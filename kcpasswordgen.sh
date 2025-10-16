#!/bin/bash
# kcpasswordEncodeHex.sh
# Generate an xxd-style hex dump for a given password

# macOS kcpassword cipher
cipher=(7D 89 52 23 D2 BC DD EA A3 B9 1F)

password="$1"

if [ -z "$password" ]; then
    echo "Usage: $0 <password>"
    exit 1
fi

# Convert password into hex array
hex=($(echo -n "$password" | xxd -p -u -c1))

# Calculate padding (to multiple of 12 bytes)
len=${#hex[@]}
if (( len < 12 )); then
    pad=$((12 - len))
elif (( len % 12 != 0 )); then
    pad=$((12 - (len % 12)))
else
    pad=12
fi

# Append padding bytes
for ((i=0; i<pad; i++)); do
    hex+=("00")
done

# XOR with cipher
out=()
for ((i=0; i<${#hex[@]}; i++)); do
    val=$(( 0x${hex[i]} ^ 0x${cipher[i % 11]} ))
    printf -v byte "%02x" "$val"
    out+=("$byte")
done

# Format like xxd dump (12 bytes per line)
printf "00000000: "
for ((i=0; i<${#out[@]}; i++)); do
    printf "%s" "${out[i]}"
    # group into 2-byte pairs
    if (( (i+1) % 2 == 0 )); then
        printf " "
    fi
done
echo