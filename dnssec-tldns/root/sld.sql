-- MySQL dump 10.13  Distrib 5.5.47, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: sld
-- ------------------------------------------------------
-- Server version	5.5.47-0+deb8u1-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `domains`
--

DROP TABLE IF EXISTS `domains`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `domains` (
  `name` varchar(255) NOT NULL,
  `ownerc_fk` varchar(12) DEFAULT NULL,
  `techc_fk` varchar(12) DEFAULT NULL,
  `adminc_fk` varchar(12) DEFAULT NULL,
  `zonec_fk` varchar(12) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT NULL,
  `dnskey1_flags` smallint(3) DEFAULT NULL,
  `dnskey1_algo` tinyint(3) unsigned DEFAULT NULL,
  `dnskey1_key` varchar(2048) DEFAULT NULL,
  `dnskey2_flags` smallint(3) DEFAULT NULL,
  `dnskey2_algo` tinyint(3) unsigned DEFAULT NULL,
  `dnskey2_key` varchar(2048) DEFAULT NULL,
  `nserver1_name` varchar(255) DEFAULT NULL,
  `nserver1_ip` varchar(16) DEFAULT NULL,
  `nserver2_name` varchar(255) DEFAULT NULL,
  `nserver2_ip` varchar(16) DEFAULT NULL,
  `nserver3_name` varchar(255) DEFAULT NULL,
  `nserver3_ip` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `domains`
--

LOCK TABLES `domains` WRITE;
/*!40000 ALTER TABLE `domains` DISABLE KEYS */;
INSERT INTO `domains` VALUES ('arminpech.de','DNSSEC-1','DNSSEC-4','DNSSEC-2','DNSSEC-3','2015-12-23 14:13:47','2016-02-29 22:11:13',0,0,'',0,0,'','ns1.dnsprovi.de','','ns2.dnsprovi.de','','',''),('babiel.com','DNSSEC-1','DNSSEC-4','DNSSEC-2','DNSSEC-3','2015-12-23 14:14:00','2015-12-29 23:31:58',0,0,'',0,0,'','ns1.foobar.de','','ns2.babiel.com','123.34.34.2','',''),('dnsprovi.de','AP-01','AP-01','AP-01','AP-01','2016-02-29 22:08:29','2016-03-13 20:12:20',257,8,'AwEAAduGeZTXLX2tgqUb+KO4Ffsd4UHFNLktX5plzou9kVTROlKuj56ZZwvk30TzpYJguUMGrhdTRwPRZ8Ey/Hv714/spXBai5rxCmi0WBalV/tyO/+tCxtiOA6PQPzmbo6PKTg5DQi47hUG1l1wfBgbmJe2xATaRY9IczrlhxKaofRfZK9UGCCmXTCRDp5mqkIZwChKpjOWTuCCiVCPcWJ6KT9pBPu92ctAfdIPr9dBO08ePYWbZnIto/3C04eEOOcUxDMKzsuhh6d8RUptM/ellHsoWsKs+1bYwdFyJLxRKPNE0t5e/RF7fBSR7cOnIivXsD76WbfAJH8lTHPPmRaoqMU=',0,0,'','ns1.dnsprovi.de','10.20.4.1','ns2.dnsprovi.de','10.20.4.2','',''),('dnssec-failed.net','','','','','2016-03-17 21:32:46','2016-03-17 22:20:18',257,8,'AwEAAcJDg0GgwSGOXXIoemEavJUGQVw9jgxLS1hBd2fSYoz8opyPANlI64V2VYvjIo7osCRdXwanZXRQECcWPpBTXXUyBJPO/lHgLES23YoR4kHbELrGEp5Pg57+83Ch07KShkKHPtq8d1KSE8XUDqud489jHolSb8S7IiWdQHq1Fe4AK6MojjNf/xpol6L9OqluEVgJd7wahybHGbQKCAKN6Izrr4aYGu8i/FsD8sr/h0uQ7Y573uZYn1l87R3Q6fHq3Vkxb8z+H8sv35AD2eXPuvaqXYA3B4sWPjPqdBgQGNPek1uzrfdX2uoh8IaF1YeqXR9/kKq8rwgaJNp+aAs56Mc=',0,0,'','ns1.dnsprovi.de','','ns2.dnsprovi.de','','',''),('dnssec.de','DNSSEC-1','DNSSEC-4','DNSSEC-2','DNSSEC-3','2015-12-24 20:59:49','2016-03-13 20:12:38',257,8,'AwEAAdLkajN2yp6G2R8kloiNmYdz0k0ZhirDU6i7BvPteilf9ti3XhIy4x5UriLFq1aHKBHM2sz6z9A72toDcWyFWqcVfD1vIdDc2OLtex2SrXfaMe3sX5XaQ7l0j6/bd54UrQSH1KURXkIAgV8F8cpWe5Y23/hnWOmszkk6Erl4DRReRdVmIQdftWfko18Y25dIjra6sz7vH2GYhctEO0GmxPsf4YX/SzNhxcch8WLY48OWfZ1u9k1QhHrz6d823mBxY86KTHLEORIpvV0/2GH7BN1ibKgu2UAo14zJk4NfeLsmypbxKA6n5Z8aAuL2fv9mStQG3lbNlMk776o510KaTFc=',0,0,'','ns1.dnsprovi.de','','ns2.dnsprovi.de','','',''),('ferrari.it','','','','','2015-12-30 23:39:49','2015-12-30 23:39:49',0,0,'',0,0,'','ns1.foobar.it','','ns2.test.it','','',''),('hills.se','FIN-123','REG-321','FIN-123','REG-321','2015-12-30 23:53:20','2015-12-30 23:53:20',0,0,'',0,0,'','ns2.hills.se','10.20.23.23','a.nss.se','','',''),('linuxtage.de','DNSSEC-1','DNSSEC-4','DNSSEC-2','DNSSEC-3','2015-12-23 14:14:07','2015-12-30 02:12:55',0,0,'',0,0,'','t1.ns14.net','123.34.46.12','t2.ns15.net','92.3.56.1','',''),('notsigned.de','AP-01','AP-01','AP-01','AP-01','2016-02-29 22:12:54','2016-02-29 22:12:54',0,0,'',0,0,'','ns1.dnsprovi.de','','ns2.dnsprovi.de','','',''),('task-rollover.de','','','','','2016-03-17 21:33:39','2016-03-17 21:33:39',257,13,'kDj1weL+wWcC6aXHZVTOOb/jrR3FHdMEwiO5o81Nt05CvwTf6wGN82rwYag704tYQXrxueifkRW+H2VNgtRJxA==',257,13,'nDmJWrSZaYfaZE1m9sTIyLHxV/+wLgLj+5lTQ42QHViI08cVY0WzzVUI+z0p8lEzLnqT0HINXQnxb2hkpT6QZg==','ns1.dnsprovi.de','','ns2.dnsprovi.de','','',''),('task-sigchase.de','','','','','2016-03-05 15:03:31','2016-03-13 20:13:02',257,8,'AwEAAaCEtwX3TlQLGwahOQQioWxzRTRBpdFIwMxwRwRhVcKv/IbDanaqT0EKmu0nWMxCWZ9os2PoEeI9+nL62/YKrIFu4yf+yfBRlfYMAQOJRyK8R/Hdc7FqHP4B8cqdNnHzNDRxoiBDmi3JGS5PWij7Z15ufqWfOEakEQJsv8Ir6fwkSl7WlooL1Av2sP9cHDb93MkR6hjdSKHE4rVqfBr3YQ2cwAMyKFzmHGrIoSy4b5zZD3IUejREfG0vkzNj06PvautO3oxk2DHbjgp0btBuB8C9p6Bg61FLrhAX7gbiozhzdJSHGUzujnkZrpLFOmY1Ri/ASZVBr1tZPl9+khYqgOk=',0,0,'','ns1.dnsprovi.de','','ns2.dnsprovi.de','','',''),('task-trace.de','','','','','2016-03-05 12:27:42','2016-03-05 12:27:42',0,0,'',0,0,'','ns1.dnsprovi.de','','ns2.dnsprovi.de','','',''),('task-whois.de','AP-2016','DNSPROVI-201','AP-2016','DNSPROVI-201','2016-03-05 12:28:26','2016-03-05 12:28:26',0,0,'',0,0,'','ns1.dnsprovi.de','','ns2.dnsprovi.de','','','');
/*!40000 ALTER TABLE `domains` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `handles`
--

DROP TABLE IF EXISTS `handles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `handles` (
  `hid` varchar(12) NOT NULL,
  `first_name` varchar(200) DEFAULT NULL,
  `last_name` varchar(200) DEFAULT NULL,
  `street` varchar(200) DEFAULT NULL,
  `zip` varchar(12) DEFAULT NULL,
  `city` varchar(200) DEFAULT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `created` datetime DEFAULT NULL,
  `updated` datetime DEFAULT NULL,
  PRIMARY KEY (`hid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `handles`
--

LOCK TABLES `handles` WRITE;
/*!40000 ALTER TABLE `handles` DISABLE KEYS */;
/*!40000 ALTER TABLE `handles` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-03-17 22:46:30
