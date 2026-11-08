#include <jni.h>
#include <stdint.h>

extern void* quick_tunnel_start(uint16_t port);
extern const char* quick_tunnel_url(void* ctx);
extern void rustls_platform_verifier_init(JNIEnv *env, jobject context);
extern void quick_tunnel_stop(void* ctx);

JNIEXPORT jlong JNICALL
Java_com_aitechdb_ghostchat_MainActivity_quick_1tunnel_1start(
    JNIEnv* env, jobject thiz, jint port) {
    void* ctx = quick_tunnel_start((uint16_t)port);
    return (jlong)(uintptr_t)ctx;
}

JNIEXPORT jstring JNICALL
Java_com_aitechdb_ghostchat_MainActivity_quick_1tunnel_1url(
    JNIEnv* env, jobject thiz, jlong ctx) {
    if (ctx == 0) return NULL;
    const char* url = quick_tunnel_url((void*)(uintptr_t)ctx);
    if (url == NULL) return NULL;
    return (*env)->NewStringUTF(env, url);
}

JNIEXPORT void JNICALL
Java_com_aitechdb_ghostchat_MainActivity_quick_1tunnel_1stop(
    JNIEnv* env, jobject thiz, jlong ctx) {
    if (ctx == 0) return;
    quick_tunnel_stop((void*)(uintptr_t)ctx);
}

JNIEXPORT void JNICALL
Java_com_aitechdb_ghostchat_MainActivity_initRustlsPlatformVerifier(JNIEnv *env, jclass clazz, jobject context) {
    // Chiama la funzione Rust corrispondente
    rustls_platform_verifier_init(env, context);
}
