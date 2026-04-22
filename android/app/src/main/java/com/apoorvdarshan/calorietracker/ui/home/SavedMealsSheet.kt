package com.apoorvdarshan.calorietracker.ui.home

import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.data.FrequentFoodGroup
import com.apoorvdarshan.calorietracker.models.FoodEntry
import com.apoorvdarshan.calorietracker.models.MealType
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.time.Instant

enum class SavedTab { RECENTS, FREQUENT, FAVORITES }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SavedMealsSheet(
    container: AppContainer,
    onDismiss: () -> Unit,
    onRelogEntry: (FoodEntry) -> Unit
) {
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    var tab by remember { mutableStateOf(SavedTab.RECENTS) }
    var recents by remember { mutableStateOf<List<FoodEntry>>(emptyList()) }
    var frequent by remember { mutableStateOf<List<FrequentFoodGroup>>(emptyList()) }
    var favorites by remember { mutableStateOf<List<FoodEntry>>(emptyList()) }
    val favKeys by container.foodRepository.favoriteKeys.collectAsState(initial = emptySet())

    LaunchedEffect(tab, favKeys) {
        when (tab) {
            SavedTab.RECENTS -> recents = container.foodRepository.recent(50)
            SavedTab.FREQUENT -> frequent = container.foodRepository.frequent()
            SavedTab.FAVORITES -> {
                val all = container.foodRepository.entries.first()
                val keys = favKeys
                favorites = all.filter { it.favoriteKey in keys }.distinctBy { it.favoriteKey }
            }
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = state,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 16.dp)) {
            Text(
                "Saved meals",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(14.dp))
            SegmentedTabs(
                selected = tab,
                onSelect = { tab = it }
            )
            Spacer(Modifier.height(16.dp))

            when (tab) {
                SavedTab.RECENTS -> RecentsList(
                    entries = recents,
                    onSelect = { onRelogEntry(it); onDismiss() },
                    onToggleFavorite = {
                        scope.launch { container.foodRepository.toggleFavorite(it) }
                    },
                    onDelete = { entry ->
                        scope.launch {
                            container.foodRepository.deleteEntry(entry.id)
                            recents = container.foodRepository.recent(50)
                        }
                    },
                    isFavorite = { it.favoriteKey in favKeys }
                )
                SavedTab.FREQUENT -> FrequentList(
                    groups = frequent,
                    onSelect = { onRelogEntry(it.template); onDismiss() },
                    onToggleFavorite = {
                        scope.launch { container.foodRepository.toggleFavorite(it.template) }
                    },
                    isFavorite = { it.template.favoriteKey in favKeys }
                )
                SavedTab.FAVORITES -> FavoritesList(
                    entries = favorites,
                    onSelect = { onRelogEntry(it); onDismiss() },
                    onUnfavorite = {
                        scope.launch { container.foodRepository.toggleFavorite(it) }
                    }
                )
            }
        }
    }
}

@Composable
private fun SegmentedTabs(selected: SavedTab, onSelect: (SavedTab) -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f))
            .padding(4.dp)
    ) {
        for (t in SavedTab.values()) {
            val isSel = t == selected
            Box(
                Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(14.dp))
                    .background(
                        if (isSel) Brush.linearGradient(listOf(AppColors.CalorieStart, AppColors.CalorieEnd))
                        else Brush.linearGradient(listOf(Color.Transparent, Color.Transparent))
                    )
                    .clickable { onSelect(t) }
                    .padding(vertical = 10.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    when (t) {
                        SavedTab.RECENTS -> "Recents"
                        SavedTab.FREQUENT -> "Frequent"
                        SavedTab.FAVORITES -> "Favorites"
                    },
                    color = if (isSel) Color.White else MaterialTheme.colorScheme.onSurface,
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}

@Composable
private fun RecentsList(
    entries: List<FoodEntry>,
    onSelect: (FoodEntry) -> Unit,
    onToggleFavorite: (FoodEntry) -> Unit,
    onDelete: (FoodEntry) -> Unit,
    isFavorite: (FoodEntry) -> Boolean
) {
    if (entries.isEmpty()) {
        EmptyState("No recent meals — log a meal to see it here.")
        return
    }
    LazyColumn(
        Modifier.fillMaxWidth().heightConstraint(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(entries, key = { it.id }) { entry ->
            MealRow(
                title = entry.name,
                subtitle = "${entry.calories} kcal · P ${entry.protein} · C ${entry.carbs} · F ${entry.fat}",
                emoji = entry.emoji ?: "🍽",
                onClick = { onSelect(entry) },
                trailing = {
                    IconButton(onClick = { onToggleFavorite(entry) }) {
                        Icon(
                            if (isFavorite(entry)) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                            contentDescription = if (isFavorite(entry)) "Unfavorite" else "Favorite",
                            tint = if (isFavorite(entry)) AppColors.Calorie else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                        )
                    }
                    IconButton(onClick = { onDelete(entry) }) {
                        Icon(Icons.Filled.Delete, contentDescription = "Delete", tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f))
                    }
                }
            )
        }
    }
}

@Composable
private fun FrequentList(
    groups: List<FrequentFoodGroup>,
    onSelect: (FrequentFoodGroup) -> Unit,
    onToggleFavorite: (FrequentFoodGroup) -> Unit,
    isFavorite: (FrequentFoodGroup) -> Boolean
) {
    if (groups.isEmpty()) {
        EmptyState("Nothing frequent yet — keep logging and your go-tos show up here.")
        return
    }
    LazyColumn(
        Modifier.fillMaxWidth().heightConstraint(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(groups, key = { it.id }) { group ->
            MealRow(
                title = group.name,
                subtitle = "${group.count}× logged · ${group.calories} kcal",
                emoji = group.template.emoji ?: "🍽",
                onClick = { onSelect(group) },
                trailing = {
                    IconButton(onClick = { onToggleFavorite(group) }) {
                        Icon(
                            if (isFavorite(group)) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
                            contentDescription = null,
                            tint = if (isFavorite(group)) AppColors.Calorie else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                        )
                    }
                }
            )
        }
    }
}

@Composable
private fun FavoritesList(
    entries: List<FoodEntry>,
    onSelect: (FoodEntry) -> Unit,
    onUnfavorite: (FoodEntry) -> Unit
) {
    if (entries.isEmpty()) {
        EmptyState("No favorites yet — tap the heart on any meal to save it here.")
        return
    }
    LazyColumn(
        Modifier.fillMaxWidth().heightConstraint(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items(entries, key = { it.favoriteKey }) { entry ->
            MealRow(
                title = entry.name,
                subtitle = "${entry.calories} kcal · P ${entry.protein} · C ${entry.carbs} · F ${entry.fat}",
                emoji = entry.emoji ?: "⭐",
                onClick = { onSelect(entry) },
                trailing = {
                    IconButton(onClick = { onUnfavorite(entry) }) {
                        Icon(Icons.Filled.Favorite, contentDescription = "Unfavorite", tint = AppColors.Calorie)
                    }
                }
            )
        }
    }
}

@Composable
private fun MealRow(
    title: String,
    subtitle: String,
    emoji: String,
    onClick: () -> Unit,
    trailing: @Composable () -> Unit
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)),
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick)
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(AppColors.Calorie.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) { Text(emoji, fontSize = 20.sp) }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold, maxLines = 1)
                Text(
                    subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                    maxLines = 1
                )
            }
            Row(verticalAlignment = Alignment.CenterVertically) { trailing() }
        }
    }
}

@Composable
private fun EmptyState(text: String) {
    Box(
        Modifier
            .fillMaxSize()
            .heightConstraint(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f)
        )
    }
}

/** Give the sheet's lazy list a stable bounded height so it's scrollable but not huge. */
@Composable
private fun Modifier.heightConstraint(): Modifier = this.height(420.dp)
