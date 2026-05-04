package com.apoorvdarshan.calorietracker.services

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import com.apoorvdarshan.calorietracker.ui.theme.AppThemeColor

object AndroidAppIconManager {
    private const val COMPONENT_NAMESPACE = "com.apoorvdarshan.calorietracker"

    private val aliases = mapOf(
        AppThemeColor.FUD_PINK to "MainActivityDefaultIcon",
        AppThemeColor.RED to "MainActivityRedIcon",
        AppThemeColor.ORANGE to "MainActivityOrangeIcon",
        AppThemeColor.GREEN to "MainActivityGreenIcon",
        AppThemeColor.MINT to "MainActivityMintIcon",
        AppThemeColor.TEAL to "MainActivityTealIcon",
        AppThemeColor.BLUE to "MainActivityBlueIcon",
        AppThemeColor.PURPLE to "MainActivityPurpleIcon"
    )

    fun apply(context: Context, themeColor: AppThemeColor) {
        val selectedAlias = aliases[themeColor] ?: aliases.getValue(AppThemeColor.FUD_PINK)
        val packageManager = context.packageManager
        val packageName = context.packageName

        setAliasState(packageManager, packageName, selectedAlias, PackageManager.COMPONENT_ENABLED_STATE_ENABLED)
        aliases.values
            .filterNot { it == selectedAlias }
            .forEach { alias ->
                setAliasState(packageManager, packageName, alias, PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
            }
    }

    private fun setAliasState(
        packageManager: PackageManager,
        packageName: String,
        alias: String,
        desiredState: Int
    ) {
        val component = ComponentName(packageName, "$COMPONENT_NAMESPACE.$alias")
        if (packageManager.getComponentEnabledSetting(component) == desiredState) return

        packageManager.setComponentEnabledSetting(
            component,
            desiredState,
            PackageManager.DONT_KILL_APP
        )
    }
}
