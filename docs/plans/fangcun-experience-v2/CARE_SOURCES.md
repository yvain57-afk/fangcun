# Copy evidence and limits

Reviewed 2026-09-19. Source text is paraphrased, not copied into product UI. No network access is added to the App.

- [NHS water and drinks](https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/water-drinks-nutrition/): general fluid guidance includes tea/coffee and varies by person. 250 ml cup and 1500 ml draft are explicit product assumptions.
- [FDA caffeine](https://www.fda.gov/consumers/consumer-updates/spilling-beans-how-much-caffeine-too-much): adult general reference and individual variability; decaf can still contain caffeine. No personal safe allowance is inferred.
- [NIAAA standard drink](https://www.niaaa.nih.gov/alcohols-effects-health/what-standard-drink): volume and ABV matter; 14 g is a US reference, not a universal serving or safety allowance.
- [NIAAA hangovers](https://www.niaaa.nih.gov/publications/brochures-and-fact-sheets/hangovers): no claim that water, coffee or breathing removes alcohol effects or guarantees recovery.
- [NIAAA alcohol overdose](https://www.niaaa.nih.gov/publications/brochures-and-fact-sheets/understanding-dangers-of-alcohol-overdose): explicit severe symptoms lead to static emergency-help guidance, not another exercise.
- [Apple notification support](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SupportingNotificationsinYourApp.html) and [scheduling](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/SchedulingandHandlingLocalNotifications.html): permission follows an explicit setting, categories register on launch, own requests can be cancelled, and asynchronous action handling persists before returning. Implementation also compiles against the installed Xcode 27 SDK.

50 mg/8 hours/30 g/6 hours and all frequency limits remain product engineering defaults, not validated individual physiology. COPY_REVIEW.csv records human editorial review as pending.
