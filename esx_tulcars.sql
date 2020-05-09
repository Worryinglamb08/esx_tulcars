CREATE DATABASE IF NOT EXISTS `essentialmode` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */;
USE `essentialmode`;

CREATE TABLE IF NOT EXISTS `tulcars_cars` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `seller` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `vehicleProps` longtext COLLATE utf8_unicode_ci NOT NULL,
  `price` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
