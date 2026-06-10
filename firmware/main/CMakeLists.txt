idf_component_register(
    SRCS "main.c" "fpga_link.c" "wifi_ap.c" "web_server.c"
    INCLUDE_DIRS "."
    REQUIRES esp_wifi esp_http_server nvs_flash driver esp_netif esp_event
)