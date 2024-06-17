# Lua Script Project Documentation

## Overview

This document provides documentation for the functions implemented in the Lua script project. Each section corresponds to a different function, explaining its purpose, parameters, and usage.

## Function: `Tainted:CreateColor`

### Description

Creates a color object based in RGB values.

### Parameters

- `r` (number): Red Game.
- `g` (number): Green Gama.
- `b` (number): Blue Gama.

### Usage

```lua
local _, ns = ...
local tainted = ns.tainted

-- create color from fractions
local colorA = tainted:CreateColor(0.78, 0, 0.22)

-- create color from values (0-255)
local colorB = tainted:CreateColor(199, 0, 57)
```

## Function: `Tainted.GetFont`

### Description

Get a FontObject by its name, if not found, then return the default value.

### Parameters

- `value` (string): Font name.

### Usage

```lua
local _, ns = ...
local tainted = ns.tainted
local font = tainted.GetFont("Tainted")
```

## Function: `Tainted.GetTexture`

### Description

Get a texture path by its name, if not found, then else return the default texture.

### Parameters

- `value` (string): Texture name.

### Usage

```lua
local _, ns = ...
local tainted = ns.tainted
local glow_texture = tainted.GetTexture("glow")
```