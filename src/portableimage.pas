{*******************************************************************************
 Portable Image File (PIF) for Lazarus/FPC/Delphi.

 This library is based on the Portable Image File (PIF) format developed by the
 [https://github.com/gfcwfzkm]. PIF is embedded systems friendly, bitmap-like
 image format with ease of use and small size.

 The more details of this image format are available at
 [https://github.com/gfcwfzkm/PIF-Image-Format].

 The Lazarus/FPC/Delphi translation is from Dilshan R Jayakody.
 [http://jayakody2000lk.blogspot.com].

 Copyright (C) 2022 Dilshan R Jayakody.

 This library is free software; you can redistribute it and/or modify it under
 the terms of the GNU Lesser General Public License as published by the
 Free Software Foundation; either version 2.1 of the License, or
 (at your option) any later version.

 This library is distributed in the hope that it will be useful, but
 WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 for more details.

 You should have received a copy of the GNU Lesser General Public License along
 with this library; if not, write to the Free Software Foundation, Inc.,
 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
 USA.
*******************************************************************************}

unit portableimage;

{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, Graphics;

const
  PIF_SIGNATURE: array[0..3] of byte =  (80, 73, 70, 0);

  // Header offsets.
  PIF_OFFSET_SIGNATURE        = $00;
  PIF_OFFSET_FILESIZE         = $04;
  PIF_OFFSET_IMAGEOFFSET      = $08;
  PIF_OFFSET_IMAGETYPE        = $0C;
  PIF_OFFSET_BITS_PER_PIXEL   = $0E;
  PIF_OFFSET_IMAGE_WIDTH      = $10;
  PIF_OFFSET_IMAGE_HEIGHT     = $12;
  PIF_OFFSET_IMAGE_SIZE       = $14;
  PIF_OFFSET_COLOR_TABLE_SIZE = $18;
  PIF_OFFSET_COMPRESSION      = $1A;
  PIF_OFFSET_COLOR_TABLE      = $1C;

  // Compression flags.
  PIF_COMPRESS = $7DDE;

  // Image type IDs.
  PIF_TYPE_RGB888 = $433C;
  PIF_TYPE_RGB565 = $E5C5;
  PIF_TYPE_RGB332 = $1E53;
  PIF_TYPE_RGB16C = $B895;
  PIF_TYPE_BLWH	  = $7DAA;
  PIF_TYPE_IND24  = $4952;
  PIF_TYPE_IND16  = $4947;
  PIF_TYPE_IND8	  = $4942;
  PIF_TYPE_INDEX  = $4900;

type
  TPortableImageException = class(Exception);
  TImageData = array of byte;
  TColorTableData = array of byte;

  TPortableImageFile = class
  private
    imgBufferStream: TMemoryStream;
    outputBitmap: TBitmap;
    imageTypeID: Word;
    outputImageWidth: Cardinal;
    outputImageHeight: Cardinal;
    procedure LoadImageFromBuffer();
    procedure DecompressRLE(var inData: TImageData; dataLen: Cardinal; bpp: Word;
      imageResolution: Cardinal);
    procedure ConvertToRGB(var inData: TImageData; imageType: Word;
      imageSize: Cardinal);
    procedure ConvertIndexedToRGB(var inData: TImageData; colorTable: TColorTableData;
      bpp: Word; imageSize: Cardinal);
    function GetFormatName() : string;
  public
    constructor Create(imagePath: String); overload;
    constructor Create(var buffer; bufferSize: LongInt); overload;
    property Image: TBitmap read outputBitmap;
    property Format: Word read imageTypeID;
    property FormatName: string read GetFormatName;
    property Width: Cardinal read outputImageWidth;
    property Height: Cardinal read outputImageHeight;
  end;

implementation

constructor TPortableImageFile.Create(var buffer; bufferSize: LongInt);
begin
  outputBitmap:= nil;

  // Load PIF data into the memory stream from the specified buffer.
  try
    imgBufferStream := TMemoryStream.Create;
    imgBufferStream.Write(buffer, bufferSize);
    LoadImageFromBuffer();
    imgBufferStream.Clear;
  finally
    // Release memory stream.
    if (Assigned(imgBufferStream)) then
    begin
      FreeAndNil(imgBufferStream);
    end;
  end;
end;

constructor TPortableImageFile.Create(imagePath: String);
begin
  outputBitmap:= nil;

  // Check availability of the PIF.
  if (FileExists(imagePath)) then
  begin
    try
      // Load PIF data into the memory stream.
      imgBufferStream := TMemoryStream.Create;
      imgBufferStream.LoadFromFile(imagePath);
      LoadImageFromBuffer();
      imgBufferStream.Clear;
    finally
      // Release memory stream.
      if (Assigned(imgBufferStream)) then
      begin
        FreeAndNil(imgBufferStream);
      end;
    end;
  end
  else
  begin
    // Specified image path is not available?
    raise TPortableImageException.CreateFmt('Unable to open image file %s', [imagePath]);
  end;
end;

procedure TPortableImageFile.DecompressRLE(var inData: TImageData; dataLen: Cardinal;
  bpp: Word; imageResolution: Cardinal);
var
  resultData: TImageData;
  resultDataSize: Cardinal;
  dataCounter, imagePointer: Cardinal;
  imageData: array [0..2] of byte;
  rleInst: ShortInt;
begin
  // Create buffer to hold the uncompressed data.
  case bpp of
    24: resultDataSize := imageResolution * 3;
    16: resultDataSize := imageResolution * 2;
    8:  resultDataSize := imageResolution;
    4:  resultDataSize := imageResolution div 2;
  else
    resultDataSize := imageResolution;
  end;

  resultData := nil;
  SetLength(resultData, resultDataSize);
  FillChar(resultData[0], resultDataSize, $7F);

  rleInst := 0;
  imagePointer :=0;
  dataCounter := 0;

  while(dataCounter < dataLen) do
  begin
    // Load next RLE compressed data.
    imageData[0] := inData[dataCounter];

    // Check the RLE instruction.
    if(rleInst > 0) then
    begin

      if(bpp >= 16) then
      begin
        dataCounter := dataCounter + 1;
        imageData[1] := inData[dataCounter];
      end;

      if(bpp = 24) then
      begin
        dataCounter := dataCounter + 1;
        imageData[2] := inData[dataCounter];
      end;

      // RLE instrunction is positive. Loop the image data rleInst times.
      while(rleInst > 0) do
      begin
        resultData[imagePointer] := imageData[0];
        imagePointer := imagePointer + 1;

        if(bpp >= 16) then
        begin
          resultData[imagePointer] := imageData[1];
          imagePointer := imagePointer + 1;
        end;

        if(bpp = 24) then
        begin
          resultData[imagePointer] := imageData[2];
          imagePointer := imagePointer + 1;
        end;

        rleInst := rleInst - 1;
      end;
    end
    else if(rleInst < 0) then
    begin
      // RLE instruction is negative. The next set of data (rleInst * -1)
      // is uncompressed.
      resultData[imagePointer] := imageData[0];
      imagePointer := imagePointer + 1;

      if(bpp >= 16) then
      begin
        dataCounter := dataCounter + 1;
        resultData[imagePointer] := inData[dataCounter];
        imagePointer := imagePointer + 1;
      end;

      if(bpp = 24) then
      begin
        dataCounter := dataCounter + 1;
        resultData[imagePointer] := inData[dataCounter];
        imagePointer := imagePointer + 1;
      end;

      rleInst := rleInst + 1;
    end
    else
    begin
      // RLE instruction is zero, load the next RLE instruction.
      rleInst := imageData[0];
    end;

    dataCounter := dataCounter + 1;
  end;

  // Replace input data buffer with uncompressed data buffer.
  SetLength(inData, resultDataSize);
  Move(resultData[0], inData[0], resultDataSize);
end;

procedure TPortableImageFile.ConvertToRGB(var inData: TImageData; imageType: Word; imageSize: Cardinal);
var
  rgbImage: TImageData;
  rgbImageLen, dataPointer, pos, inDataLen: Cardinal;
  tempColorVal: Integer;
begin
  rgbImageLen := imageSize * 3;
  rgbImage := nil;

  SetLength(rgbImage, rgbImageLen);
  FillChar(rgbImage[0], rgbImageLen, 0);

  dataPointer := 0;
  inDataLen := Length(inData);
  pos := 0;

  if(imageType = PIF_TYPE_RGB565) then
  begin
    while (pos < inDataLen) do
    begin
      rgbImage[dataPointer]     := Round(((inData[pos] and $1F) shl 3) * 1.028225806451613);
      rgbImage[dataPointer + 1] := Round((((inData[pos] and $E0) shr 3) or
        ((inData[pos + 1] and $07) shl 5)) * 1.011904762);
      rgbImage[dataPointer + 2] := Round((inData[pos + 1] and $F8) * 1.028225806451613);
      pos := pos + 2;
      dataPointer := dataPointer + 3;
    end;
  end
  else if(imageType = PIF_TYPE_RGB332) then
  begin
    while (pos < inDataLen) do
    begin
      rgbImage[dataPointer]     := Round(((inData[pos] and $03) shl 6) * 1.328125);
      rgbImage[dataPointer + 1] := Round(((inData[pos] and $1C) shl 3) * 1.138392857);
      rgbImage[dataPointer + 2] := Round((inData[pos] and $E0) * 1.138392857);
      pos := pos + 1;
      dataPointer := dataPointer + 3;
    end;
  end
  else if(imageType = PIF_TYPE_RGB16C) then
  begin
    while (pos < imageSize) do
    begin
      tempColorVal := (inData[pos div 2] and ($0F shl ((pos mod 2) * 4))) shr ((pos mod 2) * 4);
      rgbImage[dataPointer]     := Round(255 * (2.0 / 3.0 * (tempColorVal and 1)
        / 1.0 + 1.0 / 3.0 * (tempColorVal and 8) / 8.0));
      rgbImage[dataPointer + 1] := Round(255 * (2.0 / 3.0 * (tempColorVal and 2)
        / 2.0 + 1.0 / 3.0 * (tempColorVal and 8) / 8.0));
      rgbImage[dataPointer + 2] := Round(255 * (2.0 / 3.0 * (tempColorVal and 4)
        / 4.0 + 1.0 / 3.0 * (tempColorVal and 8) / 8.0));
      pos := pos + 1;
      dataPointer := dataPointer + 3;
    end;
  end
  else if(imageType = PIF_TYPE_BLWH) then
  begin
    while (pos < imageSize) do
    begin
      tempColorVal := (inData[pos div 8] and (1 shl (pos mod 8)));
      if(tempColorVal <> 0) then
      begin
        rgbImage[dataPointer] := $FF;
        rgbImage[dataPointer + 1] := $FF;
        rgbImage[dataPointer + 2] := $FF;
      end;
      pos := pos + 1;
      dataPointer := dataPointer + 3;
    end;
  end;

  // Replace input data buffer with decoded data.
  rgbImageLen := Length(rgbImage);
  SetLength(inData, rgbImageLen);
  Move(rgbImage[0], inData[0], rgbImageLen);
end;

procedure TPortableImageFile.ConvertIndexedToRGB(var inData: TImageData; colorTable:
  TColorTableData; bpp: Word; imageSize: Cardinal);
var
  rgbImage: TImageData;
  dataPointer, rgbImageLen, inDataLen, dataPos: Cardinal;
  indexCol: Integer;
begin
  dataPointer := 0;
  inDataLen := Length(inData);

  if(bpp = 3) then
  begin
    bpp := 4;
  end;

  rgbImageLen := imageSize * 3;
  rgbImage := nil;

  SetLength(rgbImage, rgbImageLen);
  FillChar(rgbImage[0], rgbImageLen, 0);

  if(bpp > 4) then
  begin
    for dataPos := 0 to (inDataLen - 1) do
    begin
      rgbImage[dataPointer]     := colorTable[inData[dataPos] * 3];
      rgbImage[dataPointer + 1] := colorTable[inData[dataPos] * 3 + 1];
      rgbImage[dataPointer + 2] := colorTable[inData[dataPos] * 3 + 2];
      dataPointer := dataPointer + 3;
    end;
  end
  else if(bpp = 4) then
  begin
    for dataPos := 0 to (imageSize - 1) do
    begin
      indexCol := inData[dataPos div 2] and ((1 shl bpp) - 1);
      inData[dataPos div (8 div bpp)] := inData[dataPos div (8 div bpp)] shr bpp;
      rgbImage[dataPointer]     := colorTable[indexCol * 3];
      rgbImage[dataPointer + 1] := colorTable[indexCol * 3 + 1];
      rgbImage[dataPointer + 2] := colorTable[indexCol * 3 + 2];
      dataPointer := dataPointer + 3;
    end;
  end
  else if(bpp = 2) then
  begin
    for dataPos := 0 to (imageSize - 1) do
    begin
      indexCol := inData[dataPos div 4] and ((1 shl bpp) - 1);
      inData[dataPos div (8 div bpp)] := inData[dataPos div (8 div bpp)] shr bpp;
      rgbImage[dataPointer]     := colorTable[indexCol * 3];
      rgbImage[dataPointer + 1] := colorTable[indexCol * 3 + 1];
      rgbImage[dataPointer + 2] := colorTable[indexCol * 3 + 2];
      dataPointer := dataPointer + 3;
    end;
  end
  else if(bpp = 1) then
  begin
    for dataPos := 0 to (imageSize - 1) do
    begin
      indexCol := inData[dataPos div 8] and ((1 shl bpp) - 1);
      inData[dataPos div (8 div bpp)] := inData[dataPos div (8 div bpp)] shr bpp;
      rgbImage[dataPointer]     := colorTable[indexCol * 3];
      rgbImage[dataPointer + 1] := colorTable[indexCol * 3 + 1];
      rgbImage[dataPointer + 2] := colorTable[indexCol * 3 + 2];
      dataPointer := dataPointer + 3;
    end;
  end;

  // Replace input data buffer with decoded data.
  SetLength(inData, rgbImageLen);
  Move(rgbImage[0], inData[0], rgbImageLen);
end;

procedure TPortableImageFile.LoadImageFromBuffer();
var
  imageOffset, imageDataSize, imageSize: Cardinal;
  bpp, colorTableSize, compression: Word;
  colorTableColors, tempImageType: Word;
  imageData: TImageData;
  colorTable: TColorTableData;
  heightPos, widthPos, dataPointer: Cardinal;
  pixelColor: TColor;

  function ReadWord(offset: cardinal): Word;
  begin
    result := (PByte(imgBufferStream.Memory)[offset]) or
      ((PByte(imgBufferStream.Memory)[offset + 1]) shl 8);
  end;

  function ReadDWord(offset: cardinal): cardinal;
  begin
    result := (PByte(imgBufferStream.Memory)[offset]) or
      ((PByte(imgBufferStream.Memory)[offset + 1]) shl 8) or
      ((PByte(imgBufferStream.Memory)[offset + 2]) shl 16) or
      ((PByte(imgBufferStream.Memory)[offset + 3]) shl 24);
  end;

begin
  imageData := nil;
  colorTable := nil;

  // Check for valid buffer size.
  imgBufferStream.Position := 0;
  if(imgBufferStream.Size < $1D) then
  begin
    raise TPortableImageException.Create('Invalid Portable Image File');
  end;

  // Check for valid image header.
  if (not CompareMem(imgBufferStream.Memory, @PIF_SIGNATURE[0], 4)) then
  begin
    raise TPortableImageException.Create('Invalid Portable Image File');
  end;

  // Load image parameters from the header block.
  imageOffset := ReadDWord(PIF_OFFSET_IMAGEOFFSET);
  imageTypeID := ReadWord(PIF_OFFSET_IMAGETYPE);
  bpp := ReadWord(PIF_OFFSET_BITS_PER_PIXEL);
  outputImageWidth := ReadWord(PIF_OFFSET_IMAGE_WIDTH);
  outputImageHeight := ReadWord(PIF_OFFSET_IMAGE_HEIGHT);
  imageDataSize := ReadDWord(PIF_OFFSET_IMAGE_SIZE);
  colorTableSize := ReadWord(PIF_OFFSET_COLOR_TABLE_SIZE);
  compression := ReadWord(PIF_OFFSET_COMPRESSION);
  imageSize := outputImageWidth * outputImageHeight;

  // Extract image data section from the PIF.
  SetLength(imageData, imageDataSize);
  imgBufferStream.Position := imageOffset;
  imgBufferStream.read(imageData[0], imageDataSize);

  // Check the compression flag and decompress the data.
  if(compression = PIF_COMPRESS) then
  begin
    DecompressRLE(imageData, imageDataSize, bpp, imageSize);
  end;

  if((imageTypeID <> PIF_TYPE_RGB888) and ((imageTypeID and $FF00) <> PIF_TYPE_INDEX)) then
  begin
    // Convert non RGB888 image data to RGB888.
    ConvertToRGB(imageData, imageTypeID, imageSize);
  end
  else if((imageTypeID and $FF00) = PIF_TYPE_INDEX) then
  begin
    case imageTypeID of
      PIF_TYPE_IND24: colorTableColors := colorTableSize div 3;
      PIF_TYPE_IND16: colorTableColors := colorTableSize div 2;
    else
      colorTableColors := colorTableSize;
    end;

    // Extract color table from the data buffer.
    SetLength(colorTable, colorTableSize);
    Move(PByte(imgBufferStream.Memory)[PIF_OFFSET_COLOR_TABLE], colorTable[0], colorTableSize);

    // Convert the color table to RGB888.
    if(imageTypeID <> PIF_TYPE_IND24) then
    begin
      if(imageTypeID = PIF_TYPE_IND16) then
      begin
        tempImageType := PIF_TYPE_RGB565;
      end
      else
      begin
        tempImageType := PIF_TYPE_RGB332;
      end;
      ConvertToRGB(TImageData(colorTable), tempImageType, colorTableColors);
    end;

    ConvertIndexedToRGB(imageData, colorTable, bpp, imageSize);
  end;

  // Create bitmap object to draw the image.
  outputBitmap := TBitmap.Create;
  outputBitmap.Width := outputImageWidth;
  outputBitmap.Height := outputImageHeight;
  outputBitmap.PixelFormat := pf24bit;

  dataPointer := 0;

  // Draw image on the bitmap canvas.
  for heightPos := 0 to (outputImageHeight - 1) do
  begin
    for widthPos := 0 to (outputImageWidth - 1) do
    begin
  {$IFDEF FPC}
      pixelColor := RGBToColor(imageData[dataPointer + 2], imageData[dataPointer + 1],
        imageData[dataPointer]);
  {$ELSE}
      pixelColor := ((imageData[dataPointer + 2]) or (imageData[dataPointer + 1] shl 8)
        or (imageData[dataPointer] shl 16));
  {$ENDIF}
      outputBitmap.Canvas.Pixels[widthPos, heightPos] := pixelColor;
      dataPointer := dataPointer + 3;
    end;
  end;
end;

function TPortableImageFile.GetFormatName() : string;
begin
  case imageTypeID of
    PIF_TYPE_RGB888 : result := 'RGB888';
    PIF_TYPE_RGB565 : result := 'RGB565';
    PIF_TYPE_RGB332 : result := 'RGB332';
    PIF_TYPE_RGB16C : result := 'RGB16C';
    PIF_TYPE_BLWH   : result := 'Black/White';
    PIF_TYPE_IND24  : result := 'Indexed 24';
    PIF_TYPE_IND16  : result := 'Indexed 16';
    PIF_TYPE_IND8   : result := 'Indexed 8';
    PIF_TYPE_INDEX  : result := 'Indexed';
  else
    result := 'Unknown';
  end;
end;

end.

