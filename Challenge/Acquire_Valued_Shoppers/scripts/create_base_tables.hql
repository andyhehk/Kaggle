drop table if exists offers;
create external table offers (
	offer int, 
	category int, 
	quantity int, 
	company int, 
	offervalue int, 
	brand int)
row format delimited fields terminated by ',' 
location '/Kaggle/Acquire_Valued_Shoppers/offers';

drop table if exists testHistory;
create external table testHistory (
	id int,
	chain int,
	offer int,
	market int,
	offerdate string)
row format delimited fields terminated by ',' 
location '/Kaggle/Acquire_Valued_Shoppers/testHistory';

drop table if exists trainHistory;
create external table trainHistory (
	id int,
	chain int,
	offer int,
	market int,
	repeattrips int,
	repeater string,
	offerdate string)
row format delimited fields terminated by ',' 
location '/Kaggle/Acquire_Valued_Shoppers/trainHistory';

drop table if exists transaction;
create external table transaction (
	id int,
	chain int,
	dept int,
	category int,
	company int,
	brand int,
	date string,
	productsize int,
	productmeasure string,
	purchasequantity int,
	purchaseamount float)
row format delimited fields terminated by ',' 
location '/Kaggle/Acquire_Valued_Shoppers/transaction';

