$key = 17

$encoded = '104122127068067112097131128116118132132'

$decoded = ''

for ($i=3;$i -le $encoded.Length;$i = $i + 3) {
    [char][byte]$bytechar = $encoded.Substring($i-3,3) - $key
    $decoded += $bytechar
}
$decoded

$decoded | clip