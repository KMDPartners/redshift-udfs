class UdfStringUtils
  UDFS = [
      {
          type:        :function,
          name:        :levenshtein,
          description: "https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#Python",
          params:      "s1 varchar(max), s2 varchar(max)",
          return_type: "integer",
          body:        %~
            import numpy as np
        
            # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#Python
            def levenshtein(source, target):
                source = source or ""
                target = target or ""
                if len(source) < len(target):
                  return levenshtein(target, source)
        
                if len(target) == 0:
                  return len(source)
        
                source = np.array(tuple(source))
                target = np.array(tuple(target))
        
                previous_row = np.arange(target.size + 1)
                for s in source:
                  current_row = previous_row + 1
                  current_row[1:] = np.minimum(current_row[1:], np.add(previous_row[:-1], target != s))
                  current_row[1:] = np.minimum( current_row[1:], current_row[0:-1] + 1)
                  previous_row = current_row
                return previous_row[-1]
            return levenshtein(s1, s2)
          ~,
          tests:       [
                           {query: "select ?('bob', 'bob')", expect: 0, example: true},
                           {query: "select ?('bob', 'boc')", expect: 1, example: true}
                       ]
      },{
          type:        :function,
          name:        :email_name,
          description: "Gets the part of the email address before the @ sign",
          params:      "email varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            if not email:
              return None
            return email.split('@')[0]
          ~,
          tests:       [
                           {query: "select ?('sam@company.com')", expect: 'sam', example: true},
                           {query: "select ?('alex@othercompany.com')", expect: 'alex', example: true},
                           {query: "select ?('bonk')", expect: 'bonk'},
                           {query: "select ?(null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :email_domain,
          description: "Gets the part of the email address after the @ sign",
          params:      "email varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            if not email:
              return None
            return email.split('@')[-1]
          ~,
          tests:       [
                           {query: "select ?('sam@company.com')", expect: 'company.com', example: true},
                           {query: "select ?('alex@othercompany.com')", expect: 'othercompany.com', example: true},
                           {query: "select ?('bonk')", expect: 'bonk'},
                           {query: "select ?(null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :url_protocol,
          description: "Gets the protocol of the URL",
          params:      "url varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            from urlparse import urlparse
            if not url:
              return None
            try:
              u = urlparse(url)
              return u.scheme
            except ValueError:
              return None
          ~,
          tests:       [
                           {query: "select ?('http://www.google.com/a')", expect: 'http', example: true},
                           {query: "select ?('https://gmail.com/b')", expect: 'https', example: true},
                           {query: "select ?('sftp://company.com/c')", expect: 'sftp', example: true},
                           {query: "select ?('bonk')", expect: ''},
                           {query: "select ?(null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :url_domain,
          description: "Gets the domain (and subdomain if present) of the URL",
          params:      "url varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            from urlparse import urlparse
            if not url:
              return None
            try:
              u = urlparse(url)
              return u.netloc
            except ValueError:
              return None
          ~,
          tests:       [
                           {query: "select ?('http://www.google.com/a')", expect: 'www.google.com', example: true},
                           {query: "select ?('https://gmail.com/b')", expect: 'gmail.com', example: true},
                           {query: "select ?('bonk')", expect: ''},
                           {query: "select ?(null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :url_path,
          description: "Gets the domain (and subdomain if present) of the URL",
          params:      "url varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            from urlparse import urlparse
            if not url:
              return None
            try:
              u = urlparse(url)
              return u.path
            except ValueError:
              return None
          ~,
          tests:       [
                           {query: "select ?('http://www.google.com/search/images?query=bob')", expect: '/search/images', example: true},
                           {query: "select ?('https://gmail.com/mail.php?user=bob')", expect: '/mail.php', example: true},
                           {query: "select ?('bonk')", expect: 'bonk'},
                           {query: "select ?(null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :url_param,
          description: "Extract a parameter from a URL",
          params:      "url varchar(max), param varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import urlparse
            if not url:
              return None
            try:
              u = urlparse.urlparse(url)
              return urlparse.parse_qs(u.query)[param][0]
            except KeyError:
              return None
          ~,
          tests:       [
                           {query: "select ?('http://www.google.com/search/images?query=bob', 'query')", expect: 'bob', example: true},
                           {query: "select ?('https://gmail.com/mail.php?user=bob&account=work', 'user')", expect: 'bob', example: true},
                           {query: "select ?('bonk', 'bonk')", expect: nil},
                           {query: "select ?(null, null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :split_count,
          description: "Split a string on another string and count the members",
          params:      "str varchar(max), delim varchar(max)",
          return_type: "int",
          body:        %~
            if not str or not delim:
              return None
            return len(str.split(delim))
          ~,
          tests:       [
                           {query: "select ?('foo,bar,baz', ',')", expect: 3, example: true},
                           {query: "select ?('foo', 'bar')", expect: 1, example: true},
                           {query: "select ?('foo,bar', 'o,b')", expect: 2},
                       ]
      },
      {
          type:        :function,
          name:        :titlecase,
          description: "Format a string as titlecase",
          params:      "str varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            if not str:
              return None
            return str.title()
          ~,
          tests:       [
                           {query: "select ?('this is a title')", expect: 'This Is A Title', example: true},
                           {query: "select ?('Already A Title')", expect: 'Already A Title', example: true},
                           {query: "select ?('')", expect: nil},
                           {query: "select ?(null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :str_multiply,
          description: "Repeat a string N times",
          params:      "str varchar(max), times integer",
          return_type: "varchar(max)",
          body:        %~
            if not str:
              return None
            return str * times
          ~,
          tests:       [
                           {query: "select ?('*', 10)", expect: '**********', example: true},
                           {query: "select ?('abc ', 3)", expect: 'abc abc abc ', example: true},
                           {query: "select ?('abc ', -3)", expect: ''},
                           {query: "select ?('', 0)", expect: nil},
                           {query: "select ?(null, 10)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :str_index,
          description: "Find the index of the first occurrence of a substring, or -1 if not found",
          params:      "full_str varchar(max), find_substr varchar(max)",
          return_type: "integer",
          body:        %~
            if not full_str or not find_substr:
              return None
            return full_str.find(find_substr)
          ~,
          tests:       [
                           {query: "select ?('Apples Oranges Pears', 'Oranges')", expect: 7, example: true},
                           {query: "select ?('Apples Oranges Pears', 'Bananas')", expect: -1, example: true},
                           {query: "select ?('abc', 'd')", expect: -1},
                           {query: "select ?('', '')", expect: nil},
                           {query: "select ?(null, null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :str_rindex,
          description: "Find the index of the last occurrence of a substring, or -1 if not found",
          params:      "full_str varchar(max), find_substr varchar(max)",
          return_type: "integer",
          body:        %~
            if not full_str or not find_substr:
              return None
            return full_str.rfind(find_substr)
          ~,
          tests:       [
                           {query: "select ?('A B C A B C', 'C')", expect: 10, example: true},
                           {query: "select ?('Apples Oranges Pears Oranges', 'Oranges')", expect: 21, example: true},
                           {query: "select ?('Apples Oranges', 'Bananas')", expect: -1, example: true},
                           {query: "select ?('abc', 'd')", expect: -1},
                           {query: "select ?('', '')", expect: nil},
                           {query: "select ?(null, null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :str_count,
          description: "Counts the number of occurrences of a substring within a string",
          params:      "full_str varchar(max), find_substr varchar(max)",
          return_type: "integer",
          body:        %~
            if not full_str or not find_substr:
              return None
            return full_str.count(find_substr)
          ~,
          tests:       [
                           {query: "select ?('abbbc', 'b')", expect: 3, example: true},
                           {query: "select ?('Apples Bananas', 'an')", expect: 2, example: true},
                           {query: "select ?('aaa', 'A')", expect: 0, example: true},
                           {query: "select ?('abc', 'd')", expect: 0},
                           {query: "select ?('', '')", expect: nil},
                           {query: "select ?(null, null)", expect: nil},
                       ]
      }, {
          type:        :function,
          name:        :remove_accents,
          description: "Remove accents from a string",
          params:      "str varchar(max)",
          return_type: "varchar(max)",
          body:        %~
            import unicodedata
            if not str:
              return None
            str = str.decode('utf-8')
            return unicodedata.normalize('NFKD', str).encode('ASCII', 'ignore')
          ~,
          tests:       [
                           {query: "select ?('café')", expect: 'cafe', example: true},
                           {query: "select ?('')", expect: nil},
                           {query: "select ?(null)", expect: nil},
                       ]
      }
    ]
end
