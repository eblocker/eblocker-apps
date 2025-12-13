import org.eblocker.app.EblockerDevice

/**
 * SampleData for eBlocker app
 */
object SampleData {
    // Sample conversation data
    val eblockerDevices = listOf(
        EblockerDevice(
            "My eBlocker",
            "http://192.168.1.1:3000/",
            "192.168.1.1",
            "eOS 3.2.3",
            "eBlocker Family Lifetime"
        ),
        EblockerDevice(
            "2nd eBlocker",
            "http://192.168.1.2:3000/",
            "192.168.1.2",
            "eOS 3.2.3",
            "eBlocker Pro"
        ),
        EblockerDevice(
            "3rd eBlocker",
            "http://192.168.1.3:3000/",
            "192.168.1.3",
            "eOS 4.0.3",
            "eBlocker Family Lifetime"
        ),
        EblockerDevice(
            "4th eBlocker",
            "http://192.168.1.4:3000/",
            "192.168.1.4",
            "eOS 3.2.3",
            "eBlocker Family Lifetime"
        ),
        EblockerDevice(
            "eBlocker Mobile",
            "http://192.168.1.5:3000/",
            "10.8.0.1",
            "eOS 3.2.3",
            "eBlocker Pro"
        )
    )
}
