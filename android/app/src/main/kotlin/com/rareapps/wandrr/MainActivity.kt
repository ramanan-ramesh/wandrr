package com.rareapps.wandrr

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.widget.ImageView
import android.widget.TextView

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.splash_screen)

        val appLogo: ImageView = findViewById(R.id.app_logo)
        val wandrrText: TextView = findViewById(R.id.wandrr_text)
        val spaceshipImageView: ImageView = findViewById(R.id.spaceship)

        val displayMetrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(displayMetrics)
        val screenWidth = displayMetrics.widthPixels

        val translationX = ObjectAnimator.ofFloat(
            spaceshipImageView,
            "translationX",
            screenWidth.toFloat(),
            -screenWidth.toFloat()
        )
        val scaleX = ObjectAnimator.ofFloat(spaceshipImageView, "scaleX", 0.5f, 1.5f)
        val scaleY = ObjectAnimator.ofFloat(spaceshipImageView, "scaleY", 0.5f, 1.5f)
        val alpha = ObjectAnimator.ofFloat(spaceshipImageView, "alpha", 1.0f, 0.0f)

        val animatorSet = AnimatorSet()
        animatorSet.duration = 3000
        animatorSet.playTogether(translationX, scaleX, scaleY, alpha)
        animatorSet.start()

        // Animate app logo fade out
        val appLogoFadeOut = ObjectAnimator.ofFloat(appLogo, "alpha", 1.0f, 0.0f)
        appLogoFadeOut.duration = 1000

        // Animate wandrr text fade in and scale
        val wandrrTextFadeIn = ObjectAnimator.ofFloat(wandrrText, "alpha", 0.0f, 1.0f)
        val wandrrTextScaleX = ObjectAnimator.ofFloat(wandrrText, "scaleX", 0.5f, 1.0f)
        val wandrrTextScaleY = ObjectAnimator.ofFloat(wandrrText, "scaleY", 0.5f, 1.0f)
        wandrrTextFadeIn.duration = 1000
        wandrrTextScaleX.duration = 1000
        wandrrTextScaleY.duration = 1000

        val textAnimatorSet = AnimatorSet()
        textAnimatorSet.playTogether(wandrrTextFadeIn, wandrrTextScaleX, wandrrTextScaleY)

        // Start animations sequentially
        val sequentialAnimatorSet = AnimatorSet()
        sequentialAnimatorSet.playSequentially(appLogoFadeOut, textAnimatorSet)
        sequentialAnimatorSet.start()

        // Delay to show the splash screen for a few seconds
        Handler(Looper.getMainLooper()).postDelayed({
            startActivity(Intent(this, FlutterAppActivity::class.java))
            finish()
        }, 3000) // 3 seconds delay
    }
}
