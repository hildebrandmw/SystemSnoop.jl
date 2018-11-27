# Settings for huge pages
const HUGEPAGE_FILE = "/sys/kernel/mm/transparent_hugepage/enabled"
abstract type TransparentHugePage end

# Make these as types to avoid writing any random stuff to the "enabled" file.
struct Always <: TransparentHugePage end
struct MAdvise <: TransparentHugePage end
struct Never <: TransparentHugePage end

string(::Type{Always}) = "always"
string(::Type{MAdvise}) = "madvise"
string(::Type{Never}) = "never"

"""
    check_hugepages() -> Bool

Return `true` if Transparent Huge Pages are disabled. If THP are enabled, also print a
warning.
"""
function check_hugepages()
    # Read from the "enabled" file, get the option that is selected.
    # Example output is from this file is:
    #
    # always [madvise] never
    #
    # where the brackets [] indicate which mode is selected.
    # The strategy is to just use a regex to get the option in the brackets and then check
    # if that is equal to "never"
    if ispath(HUGEPAGE_FILE)
        str = read(HUGEPAGE_FILE, String)
    else
        @warn """
        File $HUGEPAGE_FILE not found. Aborting hugepage check.
        """
        return false
    end

    selection = match(r"\[(.*)\]", str)

    selection === nothing && return false
    setting = first(selection.captures)
    if setting != "never"
        @warn """
        Transparent Huge Pages are not disabled. The curent setting is: "$setting".
        Disabling THP can lead to better memory tracking at the potential cost of performance.
        However, you're running MemSnoop anyways so what's another slow-down among friends?

        To disable THP, run

        juila> MemSnoop.enable_hugepages(MemSnoop.Never)

        To reenable hugepages afterwards, run

        julia> MemSnoop.enable_hugepages(MemSnoop.MAdvise)
        """

        return false
    end
    return true
end

"""
    enable_hugepages(::Type{T}) where {T <: TransparentHugePage}

Set the status of Transparent Huge Pages to `T`.
"""
enable_hugepages(::Type{T}) where {T <: TransparentHugePage} = write(HUGEPAGE_FILE, string(T))
