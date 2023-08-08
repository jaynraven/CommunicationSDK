#include "CMakeTemplateSDK.hpp"

int CallBack(int progress, const char* msg)
{
	return 0;
}

int main()
{
	auto obj = InitCMakeTemplateSDK("");
	DataType data_type;
	data_type.type = 1;
	data_type.data = "hello world";
	obj->Run(data_type, CallBack);
	DestoryCMakeTemplateSDK(obj);
	return 0;
}
