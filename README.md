# Portable Image File (PIF) library for Lazarus / Delphi
  
## Introduction

This library is based on the Portable Image File (PIF) format developed by the https://github.com/gfcwfzkm. PIF is embedded systems friendly, bitmap-like image format with ease of use and small size.

More details of this image format are available at https://github.com/gfcwfzkm/PIF-Image-Format.

This library can use to open and render the Portable Image Files on Lazarus/FPC and Delphi. It supports both Windows and Linux operating systems.

## Installation

The library is available in the `src` directory with the filename `portableimage.pas`.

### Lazarus

Open *Project Inspector* and add the `portableimage.pas` file to the project.

### Delphi

From *Project Manager* add the `portableimage.pas` file into the project.

## Usage

The following code block demonstrates opening the Portable Image File and displaying it on the *TImage*.

```
var
  pifObj: TPortableImageFile;
begin
  pifObj := TPortableImageFile.Create('sample-image.pif');
  Image1.Picture.Bitmap := pifObj.Image;
  FreeAndNil(pifObj);
end; 
```

The sample projects are available in `samples` directory for Lazarus and Delphi.
The `tests` directory contains unit tests written using Lazarus.

