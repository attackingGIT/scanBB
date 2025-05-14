#!/bin/bash

echo "" > final_results.txt
# Общие заголовки для curl
headers=(
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7'
  -H 'accept-language: ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7,zh-CN;q=0.6,zh-TW;q=0.5,zh;q=0.4'
  -H 'cache-control: max-age=0'
  -H 'dnt: 1'
  -H 'priority: u=0, i'
  -H 'referer: https://auth.standoff365.com/'
  -H 'sec-ch-ua: "Chromium";v="136", "Google Chrome";v="136", "Not.A/Brand";v="99"'
  -H 'sec-ch-ua-mobile: ?0'
  -H 'sec-ch-ua-platform: "macOS"'
  -H 'sec-fetch-dest: document'
  -H 'sec-fetch-mode: navigate'
  -H 'sec-fetch-site: same-origin'
  -H 'sec-fetch-user: ?1'
  -H 'upgrade-insecure-requests: 1'
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36'
)

# Функция для выполнения curl и обработки результата
fetch_and_process() {
  curl -s "$1" "${headers[@]}" -b "$2" | awk '{gsub(/:/, ":\n"); print}' | grep -oE '[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | grep -vE '\.(jpg|css|js|aspx|jpeg|png|gif)$' >> res.txt
}

# Основной запрос
fetch_and_process 'https://bugbounty.standoff365.com/programs' 'cookies'

# Запросы для страниц с 2 по 9
for page in {2..9}; do
  fetch_and_process "https://bugbounty.standoff365.com/programs?page=$page" 'cookies'
done

# Запросы для bizone
curl -s "https://bugbounty.bi.zone/api/bug-bounty/companies/?company_group__isnull=true&limit=100" | awk '{gsub(/:/, ":\n"); print}' | grep '"id":' -B 1 | grep "avatar" | awk -F '"' '{print $2}' > bizone.txt

for firstlink in vk sberbank astra; do
  curl -s "https://bugbounty.bi.zone/api/bug-bounty/companies/?company_group__isnull=false&limit=100&offset=0&company_group=$firstlink" | awk '{gsub(/:/, ":\n"); print}' | grep '"id":' -B 1 | grep "avatar" | awk -F '"' '{print $2}' >> bizone.txt
done

# Получение ссылок из bizone
while read -r secondlink; do
  curl -s "https://bugbounty.bi.zone/api/bug-bounty/companies/$secondlink/" | awk '{gsub(/ /, " \n"); print}' | grep -o 'https://[^/]*' >> res.txt
done < bizone.txt

# Обработка результатов
cat res.txt | sed 's/^$https\:\/\/\|http\:\/\/\|\/$//' | sed 's/,.*//' | uniq | sort -u > final_results.txt
# Удаление временных файлов
rm res.txt bizone.txt

