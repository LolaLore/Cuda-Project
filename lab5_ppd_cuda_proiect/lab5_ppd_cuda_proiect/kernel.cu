#include <cuda_runtime.h>
#include "device_launch_parameters.h"
#include <stdio.h>
#include "CImg.h"

using namespace std;
using namespace cimg_library;


__global__ void convertToBlue
	(
	unsigned char *sourceFile,		// picture sourse file
	unsigned char *destinationFile,	// picture destination file
	int width,						// picture width
	int height						// picture height
	)
{
	int pos_x = blockIdx.x * blockDim.x + threadIdx.x;
	int pos_y = blockIdx.y * blockDim.y + threadIdx.y;

	if (pos_x >= width || pos_y >= height)
		return;

	unsigned char r = sourceFile[pos_y * width + pos_x];
	unsigned char g = sourceFile[(height + pos_y) * width + pos_x];
	unsigned char b = sourceFile[(height * 2 + pos_y) * width + pos_x];

	// convert the color
	//unsigned int _gray = (unsigned int)(0.21f * r + 0.71f * g + 0.07f * b);
	//unsigned int _gray = (unsigned int)((100*b/(1+r+g))*256/(1+b+g+r));
	//r = 255 - r;
	//g = 255 - g;
	//b = 255 - b;
	unsigned int _gray = (unsigned int)((r + g + b));
	unsigned char gray = _gray > 255 ? 255 : _gray;
	//printf("%d %d %d\n", r, g, b);

	// commpose the output image
	//destinationFile[pos_y * width + pos_x] = 255-r;
	//destinationFile[(height + pos_y) * width + pos_x]=255-g;
	//destinationFile[(height * 2 + pos_y) * width + pos_x]=255-b;
	destinationFile[pos_y * width + pos_x] = b;
}

int main()
{
	CImg<unsigned char> src("D:\\Facultate_semestrul_V\\PPD\\lab5_ppd_cuda_proiect\\lab5_ppd_cuda_proiect\\pictures\\2.ppm");
	int width = src.width();
	int height = src.height();
	unsigned long size = src.size();

	//create pointer to source image
	unsigned char *srcPointer = src.data();

	CImg<unsigned char> dst(width, height, 1, 3);

	//create pointer to destination image
	unsigned char *dstPointer = dst.data();

	unsigned char *sourceFile;
	unsigned char *destinationFile;

	cudaMalloc((void**)&sourceFile, size);
	cudaMalloc((void**)&destinationFile, size);

	cudaMemcpy(sourceFile, srcPointer, size, cudaMemcpyHostToDevice);

	//launch the kernel
	dim3 blkDim(16, 16, 1);
	dim3 grdDim((width + 15) / 16, (height + 15) / 16, 1);
	convertToBlue <<< grdDim, blkDim >>> (sourceFile, destinationFile, width, height);

	//wait until kernel finishes
	cudaDeviceSynchronize();

	//copy back the result to CPU
	cudaMemcpy(dstPointer, destinationFile, width*height, cudaMemcpyDeviceToHost);

	cudaFree(sourceFile);
	cudaFree(destinationFile);

	CImgDisplay sourceDisplay(src, "Before conversion");
	CImgDisplay destinationDisplay(dst, "After conversion");

	while (!destinationDisplay.is_closed() && !sourceDisplay.is_closed())
	{
		destinationDisplay.wait();
		sourceDisplay.wait();
	}

	return 0;
}