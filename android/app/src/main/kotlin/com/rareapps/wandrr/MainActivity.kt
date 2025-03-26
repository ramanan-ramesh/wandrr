package com.rareapps.wandrr

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.core.animation.doOnEnd
import androidx.core.content.ContextCompat

class MainActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.splash_screen)

        val appLogo: ImageView = findViewById(R.id.app_logo)
        val wandrrText: TextView = findViewById(R.id.wandrr_text)
        val spaceshipImageView: ImageView = findViewById(R.id.spaceship)

        tryApplySavedTheme()

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
        val scaleY = ObjectAnimator.ofFloat(spaceshipImageView, "scaleY", 0.2f, 1.5f)
        val alpha = ObjectAnimator.ofFloat(spaceshipImageView, "alpha", 1.0f, 0.2f)

        val animatorSet = AnimatorSet()
        animatorSet.duration = 3000
        animatorSet.playTogether(translationX, scaleX, scaleY, alpha)
        animatorSet.doOnEnd {
            spaceshipImageView.visibility = View.GONE
        }
        animatorSet.start()

        val appLogoFadeOut = ObjectAnimator.ofFloat(appLogo, "alpha", 1.0f, 0.0f)
        appLogoFadeOut.duration = 2000

        val wandrrTextFadeIn = ObjectAnimator.ofFloat(wandrrText, "alpha", 0.0f, 1.0f)
        val wandrrTextScaleX = ObjectAnimator.ofFloat(wandrrText, "scaleX", 0.5f, 1.0f)
        val wandrrTextScaleY = ObjectAnimator.ofFloat(wandrrText, "scaleY", 0.5f, 1.0f)
        wandrrTextFadeIn.duration = 1000
        wandrrTextScaleX.duration = 1000
        wandrrTextScaleY.duration = 1000

        val textAnimatorSet = AnimatorSet()
        textAnimatorSet.playTogether(wandrrTextFadeIn, wandrrTextScaleX, wandrrTextScaleY)

        val sequentialAnimatorSet = AnimatorSet()
        sequentialAnimatorSet.playSequentially(appLogoFadeOut, textAnimatorSet)
        sequentialAnimatorSet.start()

        Handler(Looper.getMainLooper()).postDelayed({
            startActivity(Intent(this, FlutterAppActivity::class.java))
            finish()
        }, 3000) // 3 seconds delay
    }

    private fun tryApplySavedTheme() {
        val prefs: SharedPreferences =
            getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val themeMode = prefs.getString("flutter.themeMode", "dark")

        val rootView = findViewById<View>(R.id.splash_screen_root)
        val textView = findViewById<TextView>(R.id.wandrr_text)

        if (themeMode == "dark") {
            rootView.setBackgroundColor(ContextCompat.getColor(this, R.color.splash_dark))
            textView.setTextColor(ContextCompat.getColor(this, android.R.color.holo_green_dark))
        } else {
            rootView.setBackgroundColor(ContextCompat.getColor(this, R.color.splash_light))
            textView.setTextColor(ContextCompat.getColor(this, android.R.color.black))
        }
    }
}
