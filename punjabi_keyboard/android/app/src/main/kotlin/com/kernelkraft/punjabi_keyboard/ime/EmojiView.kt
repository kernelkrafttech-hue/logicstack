package com.kernelkraft.punjabi_keyboard.ime

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.ViewGroup
import android.widget.GridLayout
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

class EmojiView(context: Context, private val listener: Listener) : LinearLayout(context) {

    interface Listener {
        fun onCommit(text: String)
        fun onBackToKeyboard()
        fun onBackspace()
    }

    init {
        orientation = VERTICAL
        setBackgroundColor(Color.parseColor("#1E1E22"))
        setPadding(dp(6), dp(6), dp(6), dp(6))

        val tabBar = HorizontalScrollView(context)
        val tabs = LinearLayout(context).apply { orientation = HORIZONTAL }
        tabBar.addView(tabs)
        addView(tabBar, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))

        val scroller = ScrollView(context)
        val grid = GridLayout(context).apply {
            columnCount = 7
            setPadding(dp(4), dp(8), dp(4), dp(8))
        }
        scroller.addView(grid)

        for ((title, items) in EmojiPalette.all) {
            val tab = TextView(context).apply {
                text = title
                setTextColor(Color.WHITE)
                textSize = 14f
                setPadding(dp(12), dp(8), dp(12), dp(8))
            }
            tab.setOnClickListener { populate(grid, items) }
            tabs.addView(tab)
        }
        populate(grid, EmojiPalette.expressions)
        addView(scroller, LayoutParams(LayoutParams.MATCH_PARENT, 0, 1f))

        val bottom = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val back = TextView(context).apply {
            text = "ABC"
            setTextColor(Color.WHITE)
            textSize = 16f
            setPadding(dp(16), dp(10), dp(16), dp(10))
            setBackgroundColor(Color.parseColor("#2A2A2E"))
        }
        back.setOnClickListener { listener.onBackToKeyboard() }
        val del = TextView(context).apply {
            text = "⌫"
            setTextColor(Color.WHITE)
            textSize = 18f
            gravity = Gravity.CENTER
            setPadding(dp(16), dp(10), dp(16), dp(10))
            setBackgroundColor(Color.parseColor("#FF6A00"))
        }
        del.setOnClickListener { listener.onBackspace() }
        bottom.addView(back, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
        bottom.addView(del, LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f))
        addView(bottom, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
    }

    private fun populate(grid: GridLayout, items: List<String>) {
        grid.removeAllViews()
        val longText = items.any { it.length > 2 }
        grid.columnCount = if (longText) 2 else 7
        for (item in items) {
            val tv = TextView(context).apply {
                text = item
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                textSize = if (longText) 16f else 24f
                setPadding(dp(8), dp(12), dp(8), dp(12))
            }
            val lp = GridLayout.LayoutParams().apply {
                width = 0
                height = ViewGroup.LayoutParams.WRAP_CONTENT
                columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                setMargins(dp(4), dp(4), dp(4), dp(4))
            }
            tv.layoutParams = lp
            tv.setOnClickListener { listener.onCommit(item) }
            grid.addView(tv)
        }
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()
}
