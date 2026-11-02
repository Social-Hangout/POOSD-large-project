# Database Schema and Documentation

## Overview 

Data will be stored in a MongoDB database named `database`, and is organized into three collections: `users`, `recipes`, and `reviews`

## Collections 


### **Users**

| Field | Type | Required | Notes |
|--- | --- | ---| ---| 
| `_id | ObjectId | auto | | 
| firstName | string | yes | |
| lastName | string | yes | |
| passwordHash | string | yes | |
| likedRecipies | array of ObjectId | No | starts as `[]` and fills with users liked Recipes |
| createdAt | Date | yes | |

**EXAMPLE:**

```json
{
  "_id": {
    "$oid": "6ae1ba8185fc9653cd132cf4"
  },
  "firstName": "John",
  "lastName": "Smith",
  "email": "example@gmail.com",
  "passwordHash": "HASHEDPASSWORD",
  "likedRecipes": [],
  "createdAt": {
    "$date": "2026-10-28T12:00:00.000Z"
  }
}
```


### **Recipes**

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `_id` | ObjectId | auto |  |
| `title` | string | yes |  |
| `description` | string | no |  |
| `ingredients` | array of `{ name: string, amount: string }` | yes | both fields required in each item |
| `steps` | array of string | yes | one string per step, in order |
| `tags` | array of strings | no | |
| `servings` | number | no | |
| `cookingTimeMin` | number | no | |
| `avgRating` | number | no | gathered from reviews |
| `reviewCount` | number | gathered from reviews, starts at 0 |
| `createdAt` | Date | yes | | 

**EXAMPLE:**

```json
{
  "_id": {
    "$oid": "6ae1c25485fc9653cd132d01"
  },
  "title": "Brandon's Recipe",
  "description": "A great PB&J sandwich",
  "ingredients": [
    {
      "name": "bread",
      "amount": "2 slices"
    },
    {
      "name": "peanut butter",
      "amount": "2 tbsp"
    },
    {
      "name": "jelly",
      "amount": "2 tbsp"
    }
  ],
  "steps": [
    "Spread the peanut butter on the first slice",
    "Spread the peanut butter on the second slice",
    "Put the two slices togeter",
    "Voila!"
  ],
  "tags": [
    "breakfast",
    "snack",
    "quick"
  ],
  "servings": 1,
  "cookingTimeMin": 5,
  "avgRating": 5,
  "reviewCount": 1,
  "createdAt": {
    "$date": "2026-10-28T12:11:00.000Z"
  }
}
```


### **Reviews** 

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `_id` | ObjectId | auto |  |
| `recipeId` | ObjectId | yes | references `recipes._id` |
| `userId` | ObjectId | yes | references `users._id`|
| `rating` | number | yes | 1 to 5 |
| `comment` | string | no |  |
| `createdAt` | Date | yes |  |

**EXAMPLE:**

```json 
{
  "_id": {
    "$oid": "6ae1c3f385fc9653cd132d06"
  },
  "recipeId": {
    "$oid": "6ae1c38c85fc9653cd132d02"
  },
  "userId": {
    "$oid": "6ae1bed085fc9653cd132cf7"
  },
  "rating": 5,
  "comment": "the best rum&coke of all time",
  "createdAt": {
    "$date": "2026-10-28T12:30:00.000Z"
  }
}
```

### Relationships 

`ingredients`, `steps`, and `tags` are embedded in the recipe document so a recipe can be read in a single query. Reviews are stored in a separate collection because a recipe can receive many of them; each review references its recipe via `recipeId` and its author via `userId`. The recipe’s `avgRating` and `reviewCount` are derived from its reviews and must be updated whenever a review is added, changed, or removed. `likedRecipes` is an array of recipe ObjectIds on the user, and are read with the user’s profile and therefore recipes doesn't have to track who liked them.

