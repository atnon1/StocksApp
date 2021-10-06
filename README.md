# YandexStocksApp
### Stocks tracking. App for Yandex school test

Project uses Finhub API to get list of S&P500, images and companies' info via request.
Change quotes are got via Finhub API's websocket.

<img width="341" alt="image" src="https://user-images.githubusercontent.com/22581094/136243755-39cb9ed1-2649-4c90-98ff-75ff54f5a990.png">

Current issues:
* Show data only after the second openning. Probable cache issue
* Tokens are store in code
* While loading images and companies info meets API's limit for queries
* Background threads publish changes to ViewModel. Only main threads are allowed
