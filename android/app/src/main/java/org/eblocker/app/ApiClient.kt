package org.eblocker.app

import android.content.ContentValues.TAG
import android.util.Log
import kotlinx.coroutines.delay
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class ApiClient(
    val baseUrl: String
) {
    suspend fun getRegistration(): JSONObject {
        return getJson(URL(baseUrl + "/registration"))
    }

    suspend fun getSystemStatus(): JSONObject {
        return getJson(URL(baseUrl + "/api/adminconsole/systemstatus"))
    }

    suspend fun getJson(url: URL): JSONObject {
        Log.w(TAG, "Getting $url")
        val connection = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 5_000
            readTimeout = 5_000
        }
        return connection.inputStream.use { inputStream ->
            val responseText = BufferedReader(InputStreamReader(inputStream)).use { reader ->
                buildString {
                    var line: String?
                    while (true) {
                        line = reader.readLine()
                        if (line == null) break
                        append(line)
                    }
                }
            }
            val json = JSONObject(responseText)
            //delay(5000)
            json
        }
    }
}
