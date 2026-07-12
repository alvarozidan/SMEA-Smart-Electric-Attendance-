const WIB_OFFSET_MS = 7 * 60 * 60 * 1000;

function toDateOnlyWIB(date = new Date()){
    const shifted = new Date(date.getTime() + WIB_OFFSET_MS);
    return new Date(Date.UTC(shifted.getUTCFullYear(), shifted.getUTCMonth(), shifted.getUTCDate()));
}

module.exports = { toDateOnlyWIB, WIB_OFFSET_MS };