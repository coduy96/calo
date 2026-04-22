package com.apoorvdarshan.calorietracker.ui.about

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.Mail
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.foundation.Image
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.painterResource
import com.apoorvdarshan.calorietracker.R
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.ui.theme.AppColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AboutScreen(container: AppContainer) {
    val ctx = LocalContext.current

    Scaffold(topBar = { TopAppBar(title = { Text("About") }) }) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // App icon + version block
            Column(
                modifier = Modifier.fillMaxWidth().padding(vertical = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Image(
                    painter = painterResource(id = R.drawable.ic_logo),
                    contentDescription = "Fud AI logo",
                    modifier = Modifier
                        .size(84.dp)
                        .clip(CircleShape)
                )
                Text(
                    "Fud AI",
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Bold
                )
                Text("Version 1.0", style = MaterialTheme.typography.bodyMedium, color = Color(0xFF8E8E93))
                Spacer(Modifier.height(6.dp))
                Text(
                    "Open source AI calorie tracker. Free forever.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = Color(0xFF8E8E93)
                )
            }

            AboutRow(icon = Icons.Filled.Share, label = "Share the app") {
                val text = "Fud AI — free open source calorie tracker. Bring your own API key, no subscription. https://fud-ai.app"
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, text)
                }
                ctx.startActivity(Intent.createChooser(intent, "Share Fud AI"))
            }

            AboutRow(icon = Icons.Filled.Star, label = "Rate on Play Store") {
                val uri = Uri.parse("market://details?id=${ctx.packageName}")
                val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY or Intent.FLAG_ACTIVITY_NEW_DOCUMENT or Intent.FLAG_ACTIVITY_MULTIPLE_TASK)
                }
                runCatching { ctx.startActivity(intent) }.onFailure {
                    ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=${ctx.packageName}")))
                }
            }

            AboutRow(icon = Icons.Filled.Code, label = "Source on GitHub") {
                ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/apoorvdarshan/fud-ai")))
            }

            AboutRow(icon = Icons.Filled.Mail, label = "Contact: apoorv@fud-ai.app") {
                ctx.startActivity(Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:apoorv@fud-ai.app")))
            }

            AboutRow(icon = Icons.Filled.Favorite, label = "Donate") {
                ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://paypal.me/apoorvdarshan")))
            }
        }
    }
}

@Composable
private fun AboutRow(icon: ImageVector, label: String, onClick: () -> Unit) {
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick)
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(icon, contentDescription = null, tint = AppColors.Calorie)
            Spacer(Modifier.size(12.dp))
            Text(label, style = MaterialTheme.typography.bodyLarge)
        }
    }
}
