// Uart to fpga, esp32 -< fpga, the image and then fpga -> esp32 is one byte which is just the digit

#include "fpga_link.h"
#include "bnn_config.h"
#include "driver/uart.h"
#include "esp_log.h"

static const char *TAG = "fpga_link";
#define UART_RX_BUFFER_SIZE 256

esp_err_t fpga_link_init(void)
{
    const uart_config_t uart_config = {
        .baud_rate = FPGA_UART_BAUD_RATE,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };

    esp_err_t err;
    err = uart_driver_install(FPGA_UART_PORT, UART_RX_BUFFER_SIZE, 0, 0, NULL, 0);

    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to install UART driver: %s", esp_err_to_name(err));
        return err;
    }

    err = uart_param_config(FPGA_UART_PORT, &uart_config);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to configure UART parameters: %s", esp_err_to_name(err));
        return err;
    }

    err = uart_set_pin(FPGA_UART_PORT, FPGA_UART_TX_PIN, FPGA_UART_RX_PIN, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to set UART pins: %s", esp_err_to_name(err));
        return err;
    }

    return ESP_OK;
}

esp_err_t fpga_link_classify(const uint8_t *p_image, int *out_digit)
{
    // clear bytes initially
    uart_flush_input(FPGA_UART_PORT);

    int written = uart_write_bytes(FPGA_UART_PORT, (const char *)p_image, IMG_PACKED_BYTES);
    if (written != IMG_PACKED_BYTES)
    {
        ESP_LOGE(TAG, "Failed to write image data to UART: expected %d bytes, wrote %d bytes", IMG_PACKED_BYTES, written);
        return ESP_FAIL;
    }

    uint8_t reply = 0;
    int read = uart_read_bytes(FPGA_UART_PORT, &reply, 1, pdMS_TO_TICKS(FPGA_REPLY_TIMEOUT_MS));

    if (read != 1)
    {
        ESP_LOGE(TAG, "Failed to read classification result from UART: expected 1 byte, read %d bytes", read);
        return ESP_ERR_TIMEOUT;
    }

    *out_digit = reply & 0x0F; // ensure we only get the last 4 bits (0-9)
    ESP_LOGI(TAG, "Received classification result: %d", *out_digit);
    return ESP_OK;
}

esp_err_t fpga_link_loopback_test(void)
{
    uart_flush_input(FPGA_UART_PORT);

    const uint8_t test_byte = 0xA5;
    int written = uart_write_bytes(FPGA_UART_PORT, (const char *)&test_byte, 1);
    if (written != 1)
    {
        ESP_LOGE(TAG, "Loopback: failed to write test byte (wrote %d)", written);
        return ESP_FAIL;
    }

    // make sure the byte physically left the TX pin before we look for it on RX
    uart_wait_tx_done(FPGA_UART_PORT, pdMS_TO_TICKS(100));

    uint8_t rx = 0;
    int read = uart_read_bytes(FPGA_UART_PORT, &rx, 1, pdMS_TO_TICKS(200));
    if (read != 1)
    {
        ESP_LOGE(TAG, "Loopback: no byte read back (read %d) -- TX not reaching RX. Check GPIO%d->GPIO%d jumper.",
                 read, FPGA_UART_TX_PIN, FPGA_UART_RX_PIN);
        return ESP_ERR_TIMEOUT;
    }
    if (rx != test_byte)
    {
        ESP_LOGE(TAG, "Loopback: byte mismatch (sent 0x%02X, got 0x%02X) -- UART is moving data but garbling it (baud/pin issue).",
                 test_byte, rx);
        return ESP_FAIL;
    }

    ESP_LOGI(TAG, "Loopback OK: sent and received 0x%02X -- ESP32 UART is healthy.", test_byte);
    return ESP_OK;
}