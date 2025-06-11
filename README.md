# Predicting the 10-year yield
I used historical 10-year yield series and built a Random-Forest model on lagged features (1-, 2-, and 5-day lags plus simple calendar dummies). By holding out the last 20% of the data, I measured an out-of-sample RMSE of about 0.12 percentage points—showing the model can typically predict next-day yields to within ±0.12%.

Then, retraining on the full history, I rolled that model forward 10 business days. The resulting 10-day forecast gently pulls yields down from today’s ~4.50% to around ~4.30%. In practice, I could use that signal to delay buying until yields dip to your target band (e.g. sub-4.40%), or lock in now if i need certainty.

source of data = FRED DGS10
  2020-06-09 -> 2025-06-09

Plots showing the results

![10dayaheadRFForecastyield](https://github.com/user-attachments/assets/80e3d3c8-ba30-42f0-9e94-6281471bd1e8)

![actualVSpredRF](https://github.com/user-attachments/assets/c6945b5f-ff97-4961-aeee-d70100c20cc2)
