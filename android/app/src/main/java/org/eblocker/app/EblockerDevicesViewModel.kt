package org.eblocker.app

import android.content.ContentValues.TAG
import android.content.Context
import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.launch

class EblockerDevicesViewModel(context: Context): ViewModel() {
    private val repository: EblockerDevicesRepository
    val currentEblockers: LiveData<List<EblockerDevice>>
    init {
        Log.w(TAG, "Initializing EblockerDevicesViewModel")
        repository = EblockerDevicesRepository(context)
        currentEblockers = repository.currentEblockers
    }
}