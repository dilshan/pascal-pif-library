unit tstpifoperations;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, portableimage;

const
  TEST_IMAGE_FILE: string = '../data/Lenna_RGB888_rle.pif';
  TEST_IMAGE_WIDTH: Integer = 512;
  TEST_IMAGE_HEIGHT: Integer = 512;

type
  TPIFTest= class(TTestCase)
  published
    procedure LoadImageFromFile;
    procedure LoadImageFromBuffer;
  end;

implementation

procedure TPIFTest.LoadImageFromFile;
var
  pifObj: TPortableImageFile;
begin
  pifObj := TPortableImageFile.Create(TEST_IMAGE_FILE);
  CheckNotNull(pifObj.Image, 'Output image is not generated');
  CheckEquals(pifObj.Width, TEST_IMAGE_WIDTH, 'Invalid image width');
  CheckEquals(pifObj.Height, TEST_IMAGE_HEIGHT, 'Invalid image height');
  FreeAndNil(pifObj);
end;

procedure TPIFTest.LoadImageFromBuffer;
var
  memStream: TMemoryStream;
  pifObj: TPortableImageFile;
begin
  memStream := TMemoryStream.Create;
  memStream.LoadFromFile(TEST_IMAGE_FILE);
  pifObj := TPortableImageFile.Create(PByte(memStream.Memory)[0], memStream.Size);
  CheckNotNull(pifObj.Image, 'Output image is not generated');
  CheckEquals(pifObj.Width, TEST_IMAGE_WIDTH, 'Invalid image width');
  CheckEquals(pifObj.Height, TEST_IMAGE_HEIGHT, 'Invalid image height');
  FreeAndNil(pifObj);
end;

initialization

  RegisterTest(TPIFTest);
end.

