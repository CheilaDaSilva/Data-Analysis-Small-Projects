/*

NASHVILLE HOUSING DATA CLEANING WITH SQL 

*/


-- View dataset

SELECT * FROM PortfolioProject..NashvilleHousing



----------------------------------------------------------------------------------------------------------------------------



-- Remove time from 'SaleDate'

ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted Date

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)



----------------------------------------------------------------------------------------------------------------------------



-- Populate 'PropertyAddress' data

/*notes:
If there is a 'ParcelID' that is associated with an existing 'PropertyAddress' and a NULL 'PropertyAddress', 
we will substitute the null values with the existing addresses based on the parcelID
*/

-- check the parcel id's with null property addresses

SELECT DISTINCT(ParcelID), PropertyAddress FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID


--- check property addresses whose parcel id's havve instances where the property address is null 

SELECT DISTINCT(ParcelID), PropertyAddress
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NOT NULL AND 
ParcelID IN 
(
SELECT ParcelID FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL
)
ORDER BY ParcelID



--Populate by doing a self join

-- when 'PropertyAddress' is NULL it will obtain the PropertyAddress by looking at ParcelID

-- test

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	-- where parcel ids are equal but different instances/unique ids
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null
ORDER BY 1


-- update dataset to remove null 'PropertyAddress' values

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	-- where parcel ids are equal but different instances/unique ids
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]


-- view dataset

SELECT * FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL
-- no rows i.e. all nulls have been removed



----------------------------------------------------------------------------------------------------------------------------



-- Breaking out address into individual columns (address,city,state)



-- view data

SELECT PropertyAddress FROM PortfolioProject..NashvilleHousing


-- View transformations to be made before updating
-- Using CHARINDEX to specify position for extracting substrings

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
,SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) as Address
FROM PortfolioProject..NashvilleHousing


-- Split variable to get the address and update table

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)

UPDATE PortfolioProject..NashvilleHousing
SET  PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

-- Split the address to get the city and update table

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

UPDATE PortfolioProject..NashvilleHousing
SET  PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress))

-- view data

SELECT * FROM PortfolioProject..NashvilleHousing



----------------------------------------------------------------------------------------------------------------------------



-- Slipt OwnerAddress

-- view data

SELECT OwnerAddress FROM PortfolioProject..NashvilleHousing


/* 
notes:
Will be using PARSENAME - recognises periods as delimiters so we first replace all commas with periods 
and then extract substrings from there. PARSENAME reads backwards
*/


-- view transformations on data

SELECT 
-- get state
PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
-- get city
,PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)
-- get address
,PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)
FROM PortfolioProject.dbo.NashvilleHousing


-- Split 'OwnerAddress' for the address and update table

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET  OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)

-- Split 'OwnerAddress' for the city and update table

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET  OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

-- -- Split 'OwnerAddress' for the state and update table

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

UPDATE PortfolioProject.dbo.NashvilleHousing
SET  OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)


-- View data

SELECT * FROM PortfolioProject..NashvilleHousing



----------------------------------------------------------------------------------------------------------------------------

-- 'SoldAsVacant' field: Change Y and N to Yes and No, respectively.


-- View 'SoldAsVacant' values

SELECT DISTINCT(SoldAsVacant) FROM PortfolioProject..NashvilleHousing

-- View data transformed before updating dataset

SELECT DISTINCT(SoldAsVacant)
,CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM PortfolioProject..NashvilleHousing

-- Update data

UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

-- View 'Sold as Vacant' field values after transformation

SELECT DISTINCT(SoldAsVacant) FROM PortfolioProject..NashvilleHousing



----------------------------------------------------------------------------------------------------------------------------



-- Remove Duplicate values


-- Using CTE and Windows Functions to find duplicate values
-- It will attribute a row number partitioning by duplicates
-- i.e. anything that is row_num > 1 is a duplicate

WITH RowNumCTE AS 
(
SELECT *
-- Partition over variable that would be unique to each row
, ROW_NUMBER() OVER ( PARTITION BY ParcelID
								 , PropertyAddress
								 , SalePrice
								 , SaleDate
								 ,LegalReference 
								 ORDER BY UniqueID ) as row_num
FROM PortfolioProject..NashvilleHousing
)

-- view duplicates

SELECT * FROM RowNumCTE
WHERE row_num = 1
ORDER BY PropertyAddress


-- could delete these duplicates from original dataset
-- instead I will use Temp tables to follow standard data practices



-- create temp table and delete duplicates

DROP TABLE IF EXISTS NashvilleHousingTemp
CREATE TABLE NashvilleHousingTemp
(
UniqueID FLOAT
,ParcelID NVARCHAR(255)
,LandUse NVARCHAR(255)
,PropertyAddress NVARCHAR(255) 
,SaleDate DATE 
,SalePrice FLOAT
,LegalReference NVARCHAR(255)
,SoldAsVacant NVARCHAR(255)
,OwnerName NVARCHAR(255)
,OwnerAddress NVARCHAR(255)
,Acreage FLOAT
,TaxDistrict NVARCHAR(255)
,LandValue FLOAT
,BuildingValue FLOAT
,TotalValue FLOAT
,YearBuilt FLOAT
,Bedrooms FLOAT
,FullBath FLOAT
,HalfBath FLOAT
,SaleDateConverted NVARCHAR(255)
,PropertySplitAddress NVARCHAR(255)
,PropertySplitCity NVARCHAR(255)
,OwnerSplitAddress NVARCHAR(255)
,OwnerSplitCity NVARCHAR(255)
,OwnerSplitState NVARCHAR(255)
,Row_Num FLOAT
)

INSERT INTO NashvilleHousingTemp
SELECT 
UniqueID
,ParcelID 
,LandUse 
,PropertyAddress 
,SaleDate 
,SalePrice 
,LegalReference
,SoldAsVacant
,OwnerName
,OwnerAddress
,Acreage
,TaxDistrict
,LandValue
,BuildingValue
,TotalValue
,YearBuilt
,Bedrooms
,FullBath
,HalfBath
,SaleDateConverted
,PropertySplitAddress
,PropertySplitCity
,OwnerSplitAddress
,OwnerSplitCity
,OwnerSplitState
,ROW_NUMBER() OVER ( PARTITION BY ParcelID
								 , PropertyAddress
								 , SalePrice
								 , SaleDate
								 ,LegalReference 
								 ORDER BY UniqueID ) as Row_Num
FROM PortfolioProject..NashvilleHousing
-- delete duplicates from temp table
DELETE FROM NashvilleHousingTemp
WHERE Row_Num > 1

-- view temp table data with no duplicates

SELECT * FROM NashvilleHousingTemp



----------------------------------------------------------------------------------------------------------------------------



-- removing unused columns 

ALTER TABLE NashvilleHousingTemp
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate, Row_Num


-- view cleaned dataset (as temp table)

SELECT * FROM NashvilleHousingTemp



----------------------------------------------------------------------------------------------------------------------------

/* 
Could also remove the unused columns and rename the ones we use when creating the temp table
and then remove the duplicates
*/


DROP TABLE IF EXISTS NashvilleHousingTemp2
CREATE TABLE NashvilleHousingTemp2
(
UniqueID FLOAT
,ParcelID NVARCHAR(255)
,LandUse NVARCHAR(255)
,PropertyAddress NVARCHAR(255) -- split col
,PropertyCity NVARCHAR(255) -- split col
,SaleDate DATE -- converted sale date
,SalePrice FLOAT
,LegalReference NVARCHAR(255)
,SoldAsVacant NVARCHAR(255)
,OwnerName NVARCHAR(255) -- split col
,OwnerAddress NVARCHAR(255) -- split col
,OwnerCity NVARCHAR(255) -- split col
,OwnerState NVARCHAR(255) -- split col
,Acreage FLOAT
,TaxDistrict NVARCHAR(255)
,LandValue FLOAT
,BuildingValue FLOAT
,TotalValue FLOAT
,YearBuilt FLOAT
,Bedrooms FLOAT
,FullBath FLOAT
,HalfBath FLOAT
,Row_Num FLOAT
)

INSERT INTO NashvilleHousingTemp2
SELECT 
UniqueID 
,ParcelID
,LandUse
,PropertySplitAddress
,PropertySplitCity
,SaleDateConverted
,SalePrice
,LegalReference
,SoldAsVacant
,OwnerName
,OwnerSplitAddress
,OwnerSplitCity
,OwnerSplitState
,Acreage
,TaxDistrict
,LandValue
,BuildingValue
,TotalValue
,YearBuilt
,Bedrooms
,FullBath
,HalfBath
,ROW_NUMBER() OVER ( PARTITION BY ParcelID
								 , PropertyAddress
								 , SalePrice
								 , SaleDate
								 ,LegalReference 
								 ORDER BY UniqueID ) as Row_Num
FROM PortfolioProject..NashvilleHousing

-- delete duplicates from temp table
DELETE FROM NashvilleHousingTemp2
WHERE Row_Num > 1
-- drop row num col
ALTER TABLE NashvilleHousingTemp2
DROP COLUMN Row_Num

-- view cleaned dataset

SELECT * FROM NashvilleHousingTemp2


----------------------------------------------------------------------------------------------------------------------------

/* Or use views */

DROP VIEW NashHousingCleaned

CREATE VIEW NashHousingCleaned
AS
SELECT 
UniqueID 
,ParcelID
,LandUse
,PropertySplitAddress AS PropertyAddress
,PropertySplitCity AS PropertyCity
,SaleDateConverted AS SalesDate
,SalePrice
,LegalReference
,SoldAsVacant
,OwnerName
,OwnerSplitAddress AS OwnerAddress
,OwnerSplitCity AS OwnerCity
,OwnerSplitState AS OwnerState
,Acreage
,TaxDistrict
,LandValue
,BuildingValue
,TotalValue
,YearBuilt
,Bedrooms
,FullBath
,HalfBath
, ROW_NUMBER() OVER ( PARTITION BY ParcelID
								 , PropertyAddress
								 , SalePrice
								 , SaleDate
								 ,LegalReference 
								 ORDER BY UniqueID ) as Row_Num
FROM PortfolioProject..NashvilleHousing

DELETE FROM NashHousingCleaned
WHERE Row_Num > 1

SELECT * FROM NashHousingCleaned

