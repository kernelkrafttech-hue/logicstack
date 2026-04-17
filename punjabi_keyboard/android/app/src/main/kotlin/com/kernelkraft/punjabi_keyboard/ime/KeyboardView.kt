package com.kernelkraft.punjabi_keyboard.ime

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView

/**
 * Soft-keyboard view. Pure code (no xml layout) so Gurmukhi glyph rendering
 * is driven entirely by the system text renderer.
 */
class KeyboardView(
    context: Context,
    private val listener: Listener,
) : LinearLayout(context) {

    interface Listener {
        fun onCommit(text: String)
        fun onBackspace()
        fun onEnter()
        fun onSwitchLanguage()
        fun onShowEmoji()
    }

    enum class Mode { LETTERS, LETTERS_SHIFT, SYMBOLS }

    private var mode: Mode = Mode.LETTERS
    private val rowsContainer: LinearLayout

    init {
        orientation = VERTICAL
        setBackgroundColor(Color.parseColor("#1E1E22"))
        setPadding(dp(4), dp(6), dp(4), dp(6))
        rowsContainer = LinearLayout(context).apply { orientation = VERTICAL }
        addView(rowsContainer, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
        render()
    }

    fun setMode(m: Mode) {
        mode = m
        render()
    }

    private fun activeRows(): List<List<Key>> = when (mode) {
        Mode.LETTERS -> GurmukhiLayout.rows
        Mode.LETTERS_SHIFT -> GurmukhiLayout.shifted
        Mode.SYMBOLS -> SymbolLayout.rows
    }

    private fun render() {
        rowsContainer.removeAllViews()
        for (row in activeRows()) {
            val rowView = LinearLayout(context).apply {
                orientation = HORIZONTAL
                layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, dp(52)).apply {
                    topMargin = dp(3)
                    bottomMargin = dp(3)
                }
            }
            for (key in row) {
                rowView.addView(buildKey(key), LayoutParams(0, LayoutParams.MATCH_PARENT, key.weight).apply {
                    marginStart = dp(3)
                    marginEnd = dp(3)
                })
            }
            rowsContainer.addView(rowView)
        }
    }

    private fun buildKey(key: Key): View {
        val btn = TextView(context).apply {
            text = key.label
            gravity = Gravity.CENTER
            setTextColor(Color.WHITE)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
            textSize = when (key.type) {
                Key.KeyType.SPACE -> 14f
                Key.KeyType.CHAR -> 22f
                else -> 18f
            }
            setBackgroundResource(android.R.drawable.btn_default_small)
            setBackgroundColor(bgFor(key))
        }
        btn.setOnClickListener {
            performHaptic()
            dispatch(key)
        }
        if (key.longPress.isNotEmpty()) {
            btn.setOnLongClickListener { showLongPressPopup(btn, key); true }
        }
        return btn
    }

    private fun bgFor(key: Key): Int = when (key.type) {
        Key.KeyType.SPACE, Key.KeyType.CHAR, Key.KeyType.COMMA, Key.KeyType.PERIOD -> Color.parseColor("#3A3A40")
        Key.KeyType.BACKSPACE, Key.KeyType.ENTER -> Color.parseColor("#FF6A00")
        else -> Color.parseColor("#2A2A2E")
    }

    private fun dispatch(key: Key) {
        when (key.type) {
            Key.KeyType.CHAR, Key.KeyType.COMMA, Key.KeyType.PERIOD, Key.KeyType.SPACE ->
                listener.onCommit(key.output)
            Key.KeyType.BACKSPACE -> listener.onBackspace()
            Key.KeyType.ENTER -> listener.onEnter()
            Key.KeyType.SHIFT -> setMode(
                if (mode == Mode.LETTERS) Mode.LETTERS_SHIFT else Mode.LETTERS
            )
            Key.KeyType.SWITCH_SYM -> setMode(
                if (mode == Mode.SYMBOLS) Mode.LETTERS else Mode.SYMBOLS
            )
            Key.KeyType.SWITCH_LANG -> listener.onSwitchLanguage()
            Key.KeyType.EMOJI -> listener.onShowEmoji()
        }
    }

    private fun showLongPressPopup(anchor: View, key: Key) {
        val container = LinearLayout(context).apply {
            orientation = HORIZONTAL
            setBackgroundColor(Color.parseColor("#2A2A2E"))
            setPadding(dp(6), dp(6), dp(6), dp(6))
        }
        for (alt in key.longPress) {
            val tv = TextView(context).apply {
                text = alt
                setTextColor(Color.WHITE)
                textSize = 22f
                gravity = Gravity.CENTER
                setPadding(dp(12), dp(6), dp(12), dp(6))
            }
            container.addView(tv)
            tv.setOnClickListener {
                listener.onCommit(alt)
                (tv.parent as? View)?.let { }
            }
        }
        val popup = PopupWindow(container, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, true)
        popup.showAsDropDown(anchor, 0, -dp(80))
    }

    private fun performHaptic() {
        performHapticFeedback(
            HapticFeedbackConstants.KEYBOARD_TAP,
            HapticFeedbackConstants.FLAG_IGNORE_GLOBAL_SETTING
        )
    }

    private fun dp(v: Int): Int =
        (v * resources.displayMetrics.density).toInt()
}
