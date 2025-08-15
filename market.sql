CREATE TABLE IF NOT EXISTS `tq_market_stock` (
  `shop`  varchar(64) NOT NULL,
  `item`  varchar(64) NOT NULL,
  `stock` int NOT NULL DEFAULT 0,
  PRIMARY KEY (`shop`,`item`)
);
