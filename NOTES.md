gist-like minimal server
========================

requirements:

* (R1) I want to open the main page and have the ability to add a new gist
* (R2) I want to open the main page and see all snippets
* (R3) I want to be able to search for snippets
* (R4) I want to integrate documentation in between the code snippets
* (R5) I want to have versioning on my snippets

R1 - The add page
-----------------

Need to add:

* a title
* some keywords
* (*opt*) force select the language
* (*opt*) path
* the snippet

```
     __________________________________________________________ 
    |X|________________________________________________________|
    |<|>|O| http://example.com/new___________________________ ||
    |   ___________________________________________________    |
    |  | Add a new snippet                      |_COMMIT_| |   |
    |  |                   ______________________________  |   |
    |  | Title:           |_My snippet___________________| |   |
    |  |                   ______________________________  |   |
    |  | Keywords:        |_C++,integers,addition________| |   |
    |  |                   ______________________________  |   |
    |  | Language:        |_<autodetect>_______________|v| |   |
    |  |                   ______________________________  |   |
    |  | Path:            |_/General C/Basic/____________| |   |
    |  |                                                   |   |
    |  | Code:                                             |   |
    |  |  _______________________________________________  |   |
    |  | |int main(int, char* argv[]) {                  | |   |
    |  | |    int x = 2 + 2;                             | |   |
    |  | |    return x;                                  | |   |
    |  | |}                                              | |   |
    |  | |                                               | |   |
    |  | |_______________________________________________| |   |
    |  |___________________________________________________|   |
    |__________________________________________________________|
```

R2 - The directory
------------------

Will contain a windows 1.0 type directory view. Clicking on a folder shall
expand its contents. Clicking on a listing shall open the listing.

The current path shall be displayed so that the user knows where he's at.

There shall be buttons to navigate to the parent directory or to the root directory.

There shall be the possibility of returning to manually input the path.

### R2.1 - The snippet listing

Essentially opens a read-only version of the add new snippet dialog with
the COMMIT button replaced with an edit button. When clicking the edit
button, the add snippet dialog is repurposed for the edition.

The listing dialog will make use of `highlight.js` for the code listing.

The listing dialog shall have the possibility of deleting the current listing.

R3 - The search engine
----------------------

The search functionality is split between two:

1. The internal snippet search
2. The documentation search

*2.* will be ignored for now as it's part of *R4* which we won't support
until later.

*1.* shall return results prioritised as follows:

* the snippet(s) whose title(s) match the query
* partial title matches
* full keyword hits
* partial keyword hits
* code matches

The search shall bear the posibility of excluding hits by path (i.e.
the hits need to be in or in a child of the specified path)

R4 - The google integration
---------------------------

**Deferred to V4** because of complexity.

R5 - The version control
------------------------

**Deferred to V2** because of it's a nice-to-have and not a core requirement.

XX - The main page
------------------

The main page will, by default, show the snippet directory with the
following additions:

* An "add new listing" button that goes to the add new listing dialog
  The path component shall be initialized to the currently navigated path.
* The search bar

XX - The database
-----------------

A listing is a tuple consisting of:

* a unique id (ID)
* the title (TITLE)
* the path (PATH)
* a list of keywords (KEYWORDS)
* a language (LANGUAGE)
* a blob (the code) (CODE)

We need to optimize the following queries:

* query by PATH (1)
* query by ID (2)
* query by title,keyword,code
  - title (3)
  - keyword (4)
  - code (5[^dagger])

[^dagger]: only if some advanced option is enabled.

### Schema

*as a side note: the multimarkdown implementation I use breaks if there's a blank line in the middle of it (for some reason)*

``` Entry: {
    ID: uint, primary key
    TITLE: string
    PATH: string
    LANGUAGE: string, nullable, default null
    CODE: blob
}
```

``` KeywordLink: {
    NAME: string, primary key
    EntryID: uint, primary key
}
```

XX - The sort-of architecture
-----------------------------

| page          | description                           |
|---------------|---------------------------------------|
| `index.pl`    | landing page. Contains the directory view, search box, "add new snippet" buttons |
| `view.pl`     | view a listing |
| `edit.pl`     | edit a listing |
| `search.pl`   | show the results of a search |

### index.pl

Navigation will start in `/`. The current path will be passed via GET in the `path` parameter, url escaped. Optionally, a language filter can be applied via the `language` parameter.

The search box will have a check-box that enables searching the code blob itself. The default will be to only look in the title and keywords, and to filter the results by the current path.

Examples:

| path                              | result                            |
|-----------------------------------|-----------------------------------|
| `example.com/index.pl`            | defaults to `path=/`              |
| `example.com/index.pl?path=/`     | shows stuff under `/`             |
| `example.com/index.pl?path=/C&language=C++` | shows stuff under `/C/` which is in the `C++` language |

### view.pl

Same layout as `edit.pl`. `highlight.js` will be used for code highlighting.

The thing to view will be a snippet's unique id passed via GET in the `snippet` parameter.

Examples:

| path                              | result                            |
|-----------------------------------|-----------------------------------|
| `example.com/view.pl`             | error: no id                      |
| `example.com/view.pl?id=32767`    | shows the entry with id 32767     |


### edit.pl

Same as `view.pl`.

In addition, the path is passed in via the `path` parameter in order to help populating the form.

In addition, the updated data will be sent via POST in the `id`, `title`, `keywords`, `path`, `code` and `language` parameters.

If there is no snippet id passed via GET, there will be no `id` passed via POST resulting in a new snippet to be created.

When the page loads, if there is an `id` parameter, the form will be populated with the readily existing data, otherwise blank[^except].

Examples:

| path                              | result                            |
|-----------------------------------|-----------------------------------|
| `example.com/edit.pl`             | create a new entry                |
| `example.com/edit.pl?path=/C/`    | create a new entry with path set to `/C/` |
| `example.com/edit.pl?id=32767`    | edit the entry with id 32767      |
| `example.com/edit.pl?id=32767&path=/C/` | `path` is ignored           |

[^except]: with the exception of the path parameter which; if an id is supplied, the path parameter will be ignored and the field will be populated from the database; otherwise, it will be populated from the GET parameter.

### search.pl

There will be the possibility of filtering the returned list by path (but sub directories will be searched).

Examples:

| path                              | result                            |
|-----------------------------------|-----------------------------------|
| `example.com/search.pl`           | shows the search page without results |
| `example.com/search.pl?q=asd+qwe+lala` | shows the search page with results that match the query |
| `example.com/search.pl?q=asd&path=/C/` | shows results that are filtered for path |
