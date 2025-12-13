package org.eblocker.app

import android.app.Application
import android.content.ContentValues.TAG
import android.content.Context
import android.content.res.Configuration
import android.os.Bundle
import android.util.Log
import android.view.ViewGroup
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.compose.foundation.Image
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.material3.rememberTopAppBarState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.livedata.observeAsState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.eblocker.app.ui.theme.EBlockerTheme

class MainActivity : ComponentActivity() {
    @OptIn(ExperimentalMaterial3Api::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.w(TAG, "MainActivity::onCreate")
        setContent {
            EBlockerTheme {
                EblockerAppWithTopBar()
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EblockerAppWithTopBar() {
    val viewModel: EblockerDevicesViewModel = viewModel(
        factory = EblockerDevicesViewModelFactory(LocalContext.current.applicationContext)
    )
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior(rememberTopAppBarState())
    var currentUrl by remember { mutableStateOf<String?>(null) }
    if (currentUrl == null) {
        MainScreen(
            viewModel = viewModel,
            scrollBehavior = scrollBehavior,
            onOpenUrl = { url ->
                currentUrl = url
            }
        )
    } else {
        WebPageScreen(
            scrollBehavior = scrollBehavior,
            url = currentUrl!!,
            onClose = {
                currentUrl = null
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    viewModel: EblockerDevicesViewModel,
    scrollBehavior: TopAppBarScrollBehavior,
    onOpenUrl: (String) -> Unit
) {
    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),

        topBar = {
            CenterAlignedTopAppBar(
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.primary,
                ),
                title = {
                    Text(
                        "eBlocker",
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                actions = {
                    Button(onClick = {onOpenUrl("https://eblocker.org/app-help-en")}) {
                        Text("Help")
                    }
                },
                scrollBehavior = scrollBehavior,
            )
        },
    ) { innerPadding ->
        ScrollContent(
            viewModel = viewModel,
            innerPadding = innerPadding,
            onOpenUrl = onOpenUrl
        )
    }

}

@Composable
fun ScrollContent(
    viewModel: EblockerDevicesViewModel,
    innerPadding: PaddingValues,
    onOpenUrl: (String) -> Unit
) {
    val currentEblockers by viewModel.currentEblockers.observeAsState(listOf())
    Surface {
        Log.w(TAG, "ScrollContent")
        EblockerDevicesList(innerPadding, currentEblockers, onOpenUrl)
    }
}

@Composable
fun EblockerDeviceCard(
    eblockerDevice: EblockerDevice,
    onOpenUrl: (String) -> Unit
) {
    Row(Modifier.padding(8.dp)) {
        Image(
            painter = painterResource(R.drawable.icon_40_0),
            contentDescription = "eBlocker Logo",
            modifier = Modifier
                .size(40.dp)
                .clip(shape = RoundedCornerShape(percent = 15))
                .border(1.5.dp, MaterialTheme.colorScheme.primary, RoundedCornerShape(percent = 15))
        )
        Spacer(modifier = Modifier.width(8.dp))
        Column {
            Text(
                text = eblockerDevice.name,
                style = MaterialTheme.typography.titleLarge
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(getStatusAndProduct(eblockerDevice))
            Spacer(modifier = Modifier.height(4.dp))
            Text(getOsVersion(eblockerDevice))
            Spacer(modifier = Modifier.height(4.dp))
            Text(eblockerDevice.ipAddress)
            Row {
                Button(
                    onClick = {
                        onOpenUrl("http://${eblockerDevice.ipAddress}:3000/settings/")
                    },
                    modifier = Modifier.padding(all = 8.dp)
                ) {
                    Image(
                        painter = painterResource(R.drawable.settings_24px),
                        contentDescription = "Settings",
                    )
                    Text(
                        text = "Einstellungen",
                        modifier = Modifier.padding(all = 4.dp),
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
                Button(
                    onClick = {
                        onOpenUrl("http://${eblockerDevice.ipAddress}:3000/dashboard/")
                    },
                    modifier = Modifier.padding(all = 8.dp)
                ) {
                    Image(
                        painter = painterResource(R.drawable.dashboard_24px),
                        contentDescription = "Settings",
                    )
                    Text(
                        text = "Dashboard",
                        modifier = Modifier.padding(all = 4.dp),
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }
        }
    }
}

@Composable
fun getOsVersion(device: EblockerDevice): String {
    if (device.osVersion == null) {
        return String.format("eOS (%s)", stringResource(R.string.unknown_version))
    } else {
        return String.format("eOS %s", device.osVersion)
    }
}

@Composable
fun getStatusAndProduct(device: EblockerDevice): String {
    return when (device.state) {
        EblockerDeviceState.RUNNING ->
            if (device.productName == null) {
                String.format("(%s)", stringResource(R.string.not_registered))
            } else {
                normalizeProductName(device.productName!!)
            }
        EblockerDeviceState.UNKNOWN  -> stringResource(R.string.connecting)
        EblockerDeviceState.BOOTING  -> stringResource(R.string.booting)
        EblockerDeviceState.ERROR    -> stringResource(R.string.error)
        EblockerDeviceState.OFFLINE  -> stringResource(R.string.offline)
        EblockerDeviceState.UPDATING -> stringResource(R.string.installing_update)
        EblockerDeviceState.SHUTTING_DOWN -> stringResource(R.string.shutting_down)
        EblockerDeviceState.SHUTTING_DOWN_FOR_REBOOT -> stringResource(R.string.rebooting)
    }
}

fun normalizeProductName(productName: String): String {
    val regex = " ?\\(.*?\\)".toRegex()
    return productName.replace(regex, "")
}

@Preview(name = "Light Mode")
@Preview(
    uiMode = Configuration.UI_MODE_NIGHT_YES,
    showBackground = true,
    name = "Dark Mode"
)
@Composable
fun PreviewEblockerDeviceCard() {
    EBlockerTheme {
        Surface {
            EblockerDeviceCard(EblockerDevice(
                "My eBlocker",
                url = "http://192.168.0.2:3000/",
                "192.168.0.2",
                "eOS 3.2.3",
                "eBlocker Family Lifetime"),
                {}
            )
        }
    }
}

@Composable
fun EblockerDevicesList(
    innerPadding: PaddingValues,
    eblockerDevices: List<EblockerDevice>,
    onOpenUrl: (String) -> Unit
) {
    Log.w(TAG, "EblockerDevicesList")
    LazyColumn(contentPadding = innerPadding) {
        items(eblockerDevices) { device ->
            EblockerDeviceCard(device, onOpenUrl)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WebPageScreen(
    scrollBehavior: TopAppBarScrollBehavior,
    url: String,
    onClose: () -> Unit
) {
    BackHandler(onBack = onClose)

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),

        topBar = {
            CenterAlignedTopAppBar(
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.primary,
                ),
                title = {
                    Text(
                        "eBlocker Help",
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                },
                actions = {
                    Button(onClick = onClose) {
                        Text("Back")
                    }
                },
                scrollBehavior = scrollBehavior,
            )
        },
    ) { innerPadding ->


        // WebView content
        AndroidView(
            modifier = Modifier.padding(innerPadding).fillMaxSize(),
            factory = { context ->
                WebView(context).apply {
                    layoutParams = ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )

                    settings.javaScriptEnabled = true // if you need JS
                    webViewClient = WebViewClient()   // stay inside the WebView

                    loadUrl(url)
                }
            },
            update = { webView ->
                // Called when recomposed with a new url
                webView.loadUrl(url)
            }
        )
    }
}

class EblockerDevicesViewModelFactory(val context: Context) :
    ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return EblockerDevicesViewModel(context) as T
    }
}