# 💻 Nashville Housing - Data Cleaning with SQL
![project git banner](https://user-images.githubusercontent.com/88495091/209562823-7e5d23fa-447c-44a2-82a9-4a0fd874e5d8.png)

## Project Goal
Clean a dataset using SQL: 
- Fix date columns;
- Populate NULL addresses based on other columns;
- Split columns using CHARINDEX and PARSENAME; 
- Removing duplicates by creating temp tables or views.

## Dataset

Dataset was provided by [Alex The Analyst](https://github.com/AlexTheAnalyst) as part of a guided [portfolio project series](https://github.com/AlexTheAnalyst/PortfolioProjects) 

## Data Cleaning with SQL

Fixed date columns by creating a new column to obtain the correct format.
```SQL
ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted Date

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)
```

Populate Property Address to remove NULL values

```SQL
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
```

Split address columns to obtain adress, city and state columns individually:
``` SQL
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


------------------------------------------------------------------


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

```

Correct categorical labels of Sold as Vacant field:

```SQL
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

```


