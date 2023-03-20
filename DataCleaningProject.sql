/*

Cleaning Housing Data

This project shows how to clean a large data set.

*/


SELECT * FROM DataCleaning..NashvilleHousingData

-- Populate Property Address

-- Some entries in the table do not have the property address, but after some investigation, you can see that all rows with
-- the same ParcelID have the same PropertyAddress

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM DataCleaning..NashvilleHousingData a
JOIN DataCleaning..NashvilleHousingData b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- This updates the rows with no property address using other rows that have the same parcel ID

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM DataCleaning..NashvilleHousingData a
JOIN DataCleaning..NashvilleHousingData b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


-- Breaking out Address into individual columns (Address, City, State)

SELECT PropertyAddress FROM NashvilleHousingData

-- Shows two columns using the PropertyAddress column by splitting it at the comma

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,  -- Substring 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM NashvilleHousingData

-- Alter table by adding two new columns and adding the previous two columns to it

ALTER TABLE NashvilleHousingData
ADD PropertyStreetAddress NVARCHAR(255)

UPDATE NashvilleHousingData
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousingData
ADD PropertyCity NVARCHAR(255)

UPDATE NashvilleHousingData
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))



-- Now for Owner Address using a different method of splitting a string

SELECT OwnerAddress FROM NashvilleHousingData

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousingData


ALTER TABLE NashvilleHousingData
ADD OwnerStreetAddress NVARCHAR(255)

UPDATE NashvilleHousingData
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousingData
ADD OwnerCity NVARCHAR(255)

UPDATE NashvilleHousingData
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousingData
ADD OwnerState NVARCHAR(255)

UPDATE NashvilleHousingData
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



-- Change Y and N values in SoldAsVacant column to Yes and No

SELECT DISTINCT(SoldAsVacant) FROM NashvilleHousingData

SELECT SoldAsVacant,
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
FROM NashvilleHousingData

UPDATE NashvilleHousingData
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END


SELECT DISTINCT(SoldAsVacant) FROM NashvilleHousingData



-- Remove Duplicates

-- Make CTE with ROW_NUMBER() column added where the partition will show when two or more rows have the same exact values

WITH RowNumCTE AS (
SELECT *, 
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID,  -- Picking a few columns from the data that, if all are equal, should indicate duplicate rows
                 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY UniqueID) AS row_num
FROM NashvilleHousingData
)

-- Now use CTE to delete rows where the row number is greater than 1, which indicates it's an exact copy of another row

DELETE
FROM RowNumCTE
WHERE row_num > 1



-- Delete Unneeded Columns

ALTER TABLE NashvilleHousingData
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict




-- Strip leading and trailing blank spaces from a few columns

SELECT TRIM(PropertyStreetAddress), TRIM(PropertyCity)
FROM NashvilleHousingData

UPDATE NashvilleHousingData
SET PropertyStreetAddress = TRIM(PropertyStreetAddress), PropertyCity = TRIM(PropertyCity), OwnerStreetAddress = TRIM(OwnerStreetAddress),
    OwnerCity = TRIM(OwnerCity), OwnerState = TRIM(OwnerState)


SELECT * FROM NashvilleHousingData