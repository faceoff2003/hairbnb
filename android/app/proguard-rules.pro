# Exclure spécifiquement les classes problématiques
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.** { *; }
-keep class com.stripe.android.view.** { *; }
# Mais ne pas garder les classes de push provisioning
-dontwarn com.reactnativestripesdk.pushprovisioning.**