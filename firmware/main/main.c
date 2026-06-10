#include "bnn_config.h"
#include "fpga_link.h"
#include "wifi_ap.h"
#include "web_server.h"
#include "nvs_flash.h"
#include "esp_netif.h"
#include "esp_event.h"
#include "esp_log.h"

static const char *TAG = "main";

void app_main(void)
{
    esp_err_t err = nvs_flash_init();
    if (err == ESP_ERR_NVS_NO_FREE_PAGES || err == ESP_ERR_NVS_NEW_VERSION_FOUND)
    {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }

    ESP_ERROR_CHECK(err);

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    ESP_ERROR_CHECK(fpga_link_init());
    ESP_ERROR_CHECK(wifi_ap_start());
    ESP_ERROR_CHECK(web_server_start());

    ESP_LOGI(TAG, "Setup complete, server running...");
}