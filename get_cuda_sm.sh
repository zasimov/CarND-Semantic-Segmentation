#!/usr/bin/env bash

#
# Prints the compute capability of the first CUDA device installed
# on the system, or alternatively the device whose index is the
# first command-line argument

#
# Source: https://gist.githubusercontent.com/eyalroz/71ce52fa80acdd1c3b192e43a6c1d930/raw/206c4c379808e64d5571985ef0af79cf4c2a7fde/get_cuda_sm.sh

device_index=${1:-0}
timestamp=$(date +%s.%N)
gcc_binary=${CMAKE_CXX_COMPILER:-$(which c++)}
cuda_root=${CUDA_DIR:-/usr/local/cuda}
CUDA_INCLUDE_DIRS=${CUDA_INCLUDE_DIRS:-${cuda_root}/include}
CUDA_CUDART_LIBRARY=${CUDA_CUDART_LIBRARY:-${cuda_root}/lib64/libcudart.so}
generated_binary="/tmp/cuda-compute-version-helper-$$-$timestamp"
# create a 'here document' that is code we compile and use to probe the card
source_code="$(cat << EOF
#include <stdio.h>
#include <cuda_runtime_api.h>

int main()
{
	cudaDeviceProp prop;
	cudaError_t status;
	int device_count;
	status = cudaGetDeviceCount(&device_count);
	if (status != cudaSuccess) {
		fprintf(stderr,"cudaGetDeviceCount() failed: %s\n", cudaGetErrorString(status));
		return -1;
	}
	if (${device_index} >= device_count) {
		fprintf(stderr, "Specified device index %d exceeds the maximum (the device count on this system is %d)\n", ${device_index}, device_count);
		return -1;
	}
	status = cudaGetDeviceProperties(&prop, ${device_index});
	if (status != cudaSuccess) {
		fprintf(stderr,"cudaGetDeviceProperties() for device ${device_index} failed: %s\n", cudaGetErrorString(status));
		return -1;
	}
	int v = prop.major * 10 + prop.minor;
	printf("%d\\n", v);
}
EOF
)"
echo "$source_code" | $gcc_binary -x c++ -I"$CUDA_INCLUDE_DIRS" -o "$generated_binary" - -x none "$CUDA_CUDART_LIBRARY"

# probe the card and cleanup

$generated_binary
rm $generated_binary
