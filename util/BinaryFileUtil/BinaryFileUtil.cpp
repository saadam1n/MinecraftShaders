#include "BinaryFileUtil.h"

BinaryFile::BinaryFile(const char* path) {
	Handle = fopen(path, "wb");
}

BinaryFile::~BinaryFile(void) {
	fclose(Handle);
}

void BinaryFile::WriteBuffer(void* buf, size_t size) {
	fwrite(buf, sizeof(char), size, Handle);
}

float* ConvertFloatToDouble(double* buf, size_t len) {
	float* newbuf = new float[len];
	for (int index = 0; index < len; index++) {
		newbuf[index] = (float)buf[index];
	}
	return newbuf;
}