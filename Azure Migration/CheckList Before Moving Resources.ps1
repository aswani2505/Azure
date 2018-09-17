##The source and destination subscriptions must exist within the same Azure Active Directory tenant. 
##To check that both subscriptions have the same tenant ID


(Get-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise – MPN").TenantId
(Get-AzureRmSubscription -SubscriptionName "SmileDesign EA to CSP").TenantId