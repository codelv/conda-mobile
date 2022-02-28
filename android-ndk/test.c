#include <android/log.h>
#include <android/api-level.h>

int main()
{
    int sdk_ver = android_get_application_target_sdk_version();
    __android_log_print(ANDROID_LOG_DEBUG, "TEST", "SDK version: %i\n", sdk_ver);
    return 0;
}
