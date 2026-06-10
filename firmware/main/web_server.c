#include "web_server.h"
#include "web_page.h"
#include "bnn_config.h"
#include "fpga_link.h"
#include <string.h>
#include <stdio.h>
#include "esp_http_server.h"
#include "esp_log.h"

static const char *TAG = "web_server";

static const uint8_t TEST_IMAGE[IMG_PACKED_BYTES] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 0, 0, 192, 255, 31, 0, 192, 255, 3, 0, 0, 24, 0, 0, 128, 1, 0, 0, 12, 0, 0, 224, 0, 0, 0, 6, 0, 0, 112, 0, 0, 0, 3, 0, 0, 48, 0, 0, 128, 1, 0, 0, 28, 0, 0, 224, 0, 0, 0, 6, 0, 0, 48, 0, 0, 128, 3, 0, 0, 56, 0, 0, 128, 3, 0, 0, 24, 0, 0, 0, 0, 0};

static void pack_image(const uint8_t *input, uint8_t *output)
{
    memset(output, 0, IMG_PACKED_BYTES);
    for (int i = 0; i < IMAGE_PIXELS; i++)
    {
        if (input[i] > INK_THRESHOLD) // if higher than thresh
        {
            output[i / 8] |= (1u << (i % 8)); // set the bit for this pixel
        }
    }
}

static void run_classification(const uint8_t *image, char *out, size_t out_size)
{
    int digit = 0;
    esp_err_t err = fpga_link_classify(image, &digit);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Classification failed: %s", esp_err_to_name(err));
        snprintf(out, out_size, "Error");
    }
    else
    {
        snprintf(out, out_size, "%d", digit);
    }
}

static esp_err_t handle_root(httpd_req_t *req)
{
    httpd_resp_set_type(req, "text/html");
    return httpd_resp_send(req, WEB_PAGE_HTML, HTTPD_RESP_USE_STRLEN);
}

static esp_err_t handle_classify(httpd_req_t *req)
{
    if (req->content_len != IMAGE_PIXELS)
    {
        ESP_LOGW(TAG, "Invalid image size: expected %d bytes, got %d bytes", IMAGE_PIXELS, req->content_len);
        return httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Invalid image size");
    }

    uint8_t image[IMAGE_PIXELS];
    int rec = 0;
    while (rec < IMAGE_PIXELS)
    {
        int r = httpd_req_recv(req, (char *)image + rec, IMAGE_PIXELS - rec);
        if (r <= 0)
        {
            ESP_LOGE(TAG, "Failed to receive image data: %s", esp_err_to_name(r == 0 ? ESP_ERR_HTTPD_RESP_HDR : r));
            return httpd_resp_send_500(req);
        }
        rec += r;
    }

    uint8_t packed_image[IMG_PACKED_BYTES];
    pack_image(image, packed_image);

    char result[8];
    run_classification(packed_image, result, sizeof(result));

    httpd_resp_set_type(req, "text/plain");
    return httpd_resp_send(req, result, HTTPD_RESP_USE_STRLEN);
}

static esp_err_t handle_loopback(httpd_req_t *req)
{
    esp_err_t err = fpga_link_loopback_test();

    char body[80];
    int n = snprintf(body, sizeof(body), "Loopback: %s",
                     err == ESP_OK
                         ? "PASS - ESP32 UART healthy, fault is FPGA/wiring"
                         : "FAIL");

    httpd_resp_set_type(req, "text/plain");
    return httpd_resp_send(req, body, n);
}

static esp_err_t handle_test(httpd_req_t *req)
{
    char result[8];
    run_classification(TEST_IMAGE, result, sizeof(result));

    char body[32];
    int n = snprintf(body, sizeof(body), "Test result: %s", result);

    httpd_resp_set_type(req, "text/plain");
    return httpd_resp_send(req, body, n);
}

esp_err_t web_server_start(void)
{
    httpd_handle_t server = NULL;
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();

    config.lru_purge_enable = true;

    esp_err_t err = httpd_start(&server, &config);
    if (err != ESP_OK)
    {
        ESP_LOGE(TAG, "Failed to start HTTP server: %s", esp_err_to_name(err));
        return err;
    }

    httpd_uri_t root_uri = {
        .uri = "/",
        .method = HTTP_GET,
        .handler = handle_root,
    };
    httpd_uri_t classify = {
        .uri = "/classify",
        .method = HTTP_POST,
        .handler = handle_classify,
    };
    httpd_uri_t test = {
        .uri = "/test",
        .method = HTTP_GET,
        .handler = handle_test,
    };
    httpd_uri_t loopback = {
        .uri = "/loopback",
        .method = HTTP_GET,
        .handler = handle_loopback,
    };
    httpd_register_uri_handler(server, &root_uri);
    httpd_register_uri_handler(server, &classify);
    httpd_register_uri_handler(server, &test);
    httpd_register_uri_handler(server, &loopback);

    ESP_LOGI(TAG, "HTTP server started");
    return ESP_OK;
}