#include "wifi_ap.h"
#include "bnn_config.h"
#include <string.h>
#include "esp_wifi.h"
#include "esp_netif.h"
#include "esp_log.h"

static const char *TAG = "wifi_ap";

esp_err_t wifi_ap_start(void)
{
    // create network interface
    esp_netif_create_default_wifi_ap();

    wifi_init_config_t init_cfg = WIFI_INIT_CONFIG_DEFAULT();
    esp_err_t err = esp_wifi_init(&init_cfg);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to initialize WiFi: %s", esp_err_to_name(err));
        return err;
    }

    wifi_config_t ap_cfg = {
        .ap = {
            .ssid = AP_SSID,
            .ssid_len = strlen(AP_SSID),
            .channel = AP_CHANNEL,
            .password = AP_PASSWORD,
            .max_connection = AP_MAX_CONNECTIONS,
            .authmode = WIFI_AUTH_WPA2_PSK,
        },
    };

    err = esp_wifi_set_mode(WIFI_MODE_AP);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to set WiFi mode: %s", esp_err_to_name(err));
        return err;
    }
    err = esp_wifi_set_config(WIFI_IF_AP, &ap_cfg);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to set WiFi AP config: %s", esp_err_to_name(err));
        return err;
    }
    err = esp_wifi_start();
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to start WiFi: %s", esp_err_to_name(err));
        return err;
    }

    ESP_LOGI(TAG, "WiFi AP started with SSID: %s", AP_SSID);
    return ESP_OK;
}