----OURTASK IS TO CLEAN THIS DATA BY PERFORMING THE FOLLOWING TASKS
--1. Standardize the date format
--2. Populate the missing values in the PropertyAddress column
--3. Split the PropertyAddress column into 3 columns(Address,city,state)
--4. Split the Ownership Address into it's individual columns
--5. Transform the SoldAsVacant column by changing Y to Yes and N to NO
--6. Remove duplicates
--7. Remove unused columns

SELECT *,CONVERT(date,SaleDate) AS New_date
FROM Housing

ALTER TABLE Housing
Add New_date Date

UPDATE Housing
SET New_date = CONVERT(date,SaleDate) 


--Populate the PropertyAdress column
--we will perform a self join here in order to compare columns from the same table, this will help us check if the parcel id matches 
--with the propertyaddress

SELECT a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress
FROM Housing a
join Housing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null


--we will use the ISNULL fn to populate the missing values and then update our table
SELECT a.ParcelID,
		a.PropertyAddress,
		b.ParcelID,b.PropertyAddress,
		ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Housing a
join Housing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null


UPDATE a --Note that when updating a table using joins the Alias isused instead of the table name.
SET a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress) --we can also decide to populate the missing values with any string of our choice, e.g ISNULL(a.PropertyAddress,'No Address')
FROM Housing a
join Housing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null



--Breaking out the PropertyAddress column into it's individual columns(Address,City,State)

SELECT
	SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City
FROM Housing

ALTER TABLE Housing
Add Property_Address nvarchar(255)

ALTER TABLE Housing
Add Property_City nvarchar(255)

UPDATE Housing
SET Property_Address = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)

UPDATE Housing
SET Property_City = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))



--Breaking out the OwnerAddress column into it's individual columns(Address,City,State)
--But instead of using the SUBSTRING FN, we will use the PARSENAME FN which is much simpler. but parselname only work with period delimeters
--so we must firt covnert our commas to periods b4 using this fn. and again it arranges output backwards  so we will have to pt the number we want 1st last and vice versa

SELECT 
	PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM Housing

--NOW WE WILL CREATE NEW COLUMNS AND UPDATE OUR TABLE

ALTER TABLE Housing
Add Owner_Address nvarchar(255)

ALTER TABLE Housing
Add Owner_City nvarchar(255)

ALTER TABLE Housing
Add Owner_State nvarchar(255)

UPDATE Housing
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE Housing
SET Owner_City = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE Housing
SET Owner_State = PARSENAME(REPLACE(OwnerAddress,',','.'),1)



--The SoldAsVacant column contains 4 distinct valeus 'Yes','NO','Y', & 'N'.So we will transfrom the column and change the Y to Yes and N to NO.

SELECT SoldAsVacant,
	COUNT(*)
FROM Housing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT
	CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		 WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant END 
FROM Housing

UPDATE Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		 WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant END


--Let's get rid of duplicate data. Note that it is not good practice to delete data without appropriate instructions from ur stakeholder
--the integrity of your data should always be top of mind

WITH CTE AS (
SELECT *,
	ROW_NUMBER() OVER(PARTITION BY ParcelID,
					  PropertyAddress,
					  SalePrice,
					  SaleDate,
					  LegalReference
					  ORDER BY [UniqueID ]) AS ROW_NUM
FROM Housing
)
DELETE
FROM CTE
WHERE ROW_NUM >1

--And finally lets remove the columns we won't be needing for our analysis. again get permission from the appropriate body before 
--making any permanent change to your data

ALTER TABLE Housing
DROP COLUMN PropertyAddress,
			LegalReference,
			OwnerAddress,
			TaxDistrict,
			SaleDate


SELECT *
FROM Housing