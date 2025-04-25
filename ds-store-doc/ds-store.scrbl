#lang scribble/manual
@(require (for-label ds-store
                     ds-store/alias
                     ds-store/cross-alias
                     racket/base
                     racket/contract/base))

@title{Reading Writing @filepath{.DS_Store} Files}

A @filepath{.DS_Store} file is a metadata file on Mac OS X that holds
information about folder and icons as viewed and manipulated in
Finder. One common reason to manipulate @filepath{.DS_Store} files
is to create a nice-looking disk image for a Mac OS X installer.

@filepath{.DS_Store} reading and writing is based on a
reverse-engineered description of the file format @cite["DS_Store"].

@section[#:tag "ds-store-api"]{@filepath{.DS_Store} Files and Entries}

@defmodule[ds-store]

@defproc[(read-ds-store [path path-string?]
                        [#:verbose verbose? any/c #f])
         (listof ds?)]{

Reads the @filepath{.DS_Store} file at @racket[path] returning a list
of store items.}

@defproc[(write-ds-store [path path-string?]
                         [dses (listof ds?)])
         void?]{

Writes @racket[dses] to the @filepath{.DS_Store} file at
@racket[path], replacing the file's current content.}

@defstruct*[ds ([path (or/c path-element? 'same)]
                [id symbol?]
                [type (or/c 'long 'shor 'bool 'type 'ustr 'blob)]
                [data (or/c exact-integer? boolean? symbol? string?
                            bytes? iloc? fwind?)])
            #:transparent]{

Represents a entry in a @filepath{.DS_Store} file. A
@filepath{.DS_Store} file typically has multiple entries for a single
file or directory in the same directory as the @filepath{.DS_Store}.

The @racket[path] should be @racket['same] only for a volume root
directory; information about a directory is otherwise recorded in its
parent directory's @filepath{.DS_Store} file.

The @racket[id] symbols should each have four ASCII characters. See
the @filepath{.DS_Store} format description @cite["DS_Store"] for more
information @racket[id] and @racket[type] values.

The @racket[data] field long should be an exact integer for
@racket['long] and @racket['shor] types, a boolean for the
@racket['bool] type, a 4-character ASCII symbol for the @racket['type]
type, a string for the @racket['ustr] type, and either a byte string,
@racket[iloc], or @racket[fwind] for the @racket['blob] type.}

@defstruct*[iloc ([x exact-integer?] [y exact-integer?]) #:transparent]{

Represents an icon location for an @racket['Iloc] entry.}

@defstruct*[fwind ([t exact-integer?]
                   [l exact-integer?]
                   [b exact-integer?]
                   [r exact-integer?]
                   [mode symbol?]
                   [sideview? any/c])
            #:transparent]{

Represent a window location for a @racket['fwi0] entry. The
@racket[mode] field should have four ASCII characters, and recognized
@racket[mode]s include @racket['icnv], @racket['clmv], and
@racket['Nlsv].}

@; ----------------------------------------

@section[#:tag "aliases"]{Finder Aliases}

A @racket['pict] entry in a @filepath{.DS_Store} file references a
file through a Finder alias. See also @racketmodname[ds-store/cross-alias].

@defmodule[ds-store/alias]

@defproc[(path->alias-bytes [path path-string?]
                            [#:wrt wrt-dir (or/c #f path-string?) #f])
         (or/c bytes? #f)]{

Constructs a byte string to represent a Finder alias but using the
@filepath{CoreFoundation} library on Mac OS.

See also @racket[path->synthesized-alias-bytes].}

@; ----------------------------------------

@section[#:tag "cross-aliases"]{Cross-Built Finder Aliases}

@defmodule[ds-store/cross-alias]

@history[#:added "1.1"]

@defproc[(path->synthesized-alias-bytes [#:volume-name volume-name string?]
                                        [#:file-name file-name string?]
                                        [#:file-inode file-inode exact-integer?]
                                        [#:parent-name parent-name string?]
                                        [#:parent-inode parent-inode exact-integer?]
                                        [#:file-absolute-name file-absolute-name string?]
                                        [#:file-absolute-path-within-volume file-absolute-path-within-volume string?]
                                        [#:volume-maybe-absolute-path volume-maybe-absolute-path string?])
         bytes?]{

Like @racket[path->alias-bytes], but creates alias bytes without using
Mac OS libraries, which requires specifying details of the filesystem
for the alias:

@itemlist[

 @item{@racket[volume-name]: The name of the volume.}

 @item{@racket[file-name]: The name of a file referenced by the alias,
 not including its path.}

 @item{@racket[file-inode]: The inode the referenced file (in the same
 sense as the @racket['inode] result of
 @racket[file-or-directory-stat]).}

 @item{@racket[parent-name]: The name of the directory containing the
 referenced file, not including the directory's path. If the
 referenced file is in the volume's root directory,
 @racket[parent-name] will be @racket[volume-name].}

 @item{@racket[parent-inode]: The inode of the file's enclosing
 directory (in the same sense as the @racket['inode] result of
 @racket[file-or-directory-stat]).}

 @item{@racket[file-absolute-name]: The full path to the referenced
 file, but using Mac OS Classic path syntax, so path elements are
 separated by @litchar{:}s. This path starts with @racket[volume-name]
 and ends with @racket[file-name].}

 @item{@racket[file-absolute-path-within-volume]: The full path to the
 referenced file using Unix path conventions. If the referenced file
 is in the volume's root directory, this path is @racket[file-name]
 prefixed with @litchar{/}.}

 @item{@racket[volume-maybe-absolute-path]: A prediction of how the
 volume will be mounted, normally @racket[volume-name] prefixed with
 @litchar{/Volumes/}.}

]

Alias synthesis is based on a reverse-engineered description of the
alias format @cite["Alias"].

}

@; ----------------------------------------

@bibliography[(bib-entry #:key "DS_Store"
                         #:title "DS_Store Format"
                         #:author "Wim Lewis and Mark Mentovai"
                         #:url "http://search.cpan.org/~wiml/Mac-Finder-DSStore/DSStoreFormat.pod")
              (bib-entry #:key "Alias"
                         #:title "Alias (Mac OS)"
                         #:author "Wikipedia"
                         #:url "https://en.wikipedia.org/wiki/Alias_(Mac_OS)")]
