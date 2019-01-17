;;
;;
;; Verifying the digraph package. Code adapted from the Boost graph
;; library dependency example.
;;
;; Copyright 2007-2018 Ivan Raikov.
;;
;;
;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; A full copy of the GPL license can be found at
;; <http://www.gnu.org/licenses/>."))))
;;

(import scheme (chicken base) (chicken format)
        (only srfi-1 delete-duplicates concatenate list-tabulate zip)
        digraph graph-cycles test)


(define used-by
   (list 
     (cons 'dax_h 'foo_cpp) (cons 'dax_h 'bar_cpp) (cons 'dax_h 'yow_h)
     (cons 'yow_h 'bar_cpp) (cons 'yow_h 'zag_cpp) (cons 'boz_h 'bar_cpp)
     (cons 'boz_h 'zig_cpp) (cons 'boz_h 'zag_cpp) (cons 'zow_h 'foo_cpp)
     (cons 'foo_cpp 'foo_o) (cons 'foo_o 'libfoobar_a) 
     (cons 'bar_cpp 'bar_o) (cons 'bar_o 'libfoobar_a) 
     (cons 'libfoobar_a 'libzigzag_a)  (cons 'zig_cpp 'zig_o) 
     (cons 'zig_o 'libzigzag_a) (cons 'libfoobar_a 'dax_h) (cons 'zag_cpp 'zag_o) 
     (cons 'zag_o 'libzigzag_a) (cons 'libzigzag_a 'killerapp)))


(define node-list
  (delete-duplicates
   (concatenate (list (map car used-by) (map cdr used-by)))))

(define node-ids
  (list-tabulate (length node-list) values))

(define node-map  (zip node-list node-ids)) 

(test-group "graph cycles test"

  (let ((g (make-digraph 'depgraph "dependency graph")))
    
    ;; add the nodes to the graph
    (for-each (lambda (i n) (add-node! g i n))
	      node-ids node-list)
    
    ;; make sure all nodes got inserted
    (test "add nodes to the graph"
	  (nodes g)
	  '((14 killerapp)
	    (13 libzigzag_a) (12 zag_o) (11 zag_cpp)
	    (10 zig_o) (9 zig_cpp) (8 libfoobar_a) (7 bar_o)
	    (6 bar_cpp) (5 foo_o) (4 foo_cpp) (3 zow_h) (2 boz_h)
	    (1 yow_h) (0 dax_h)))
    
    ;; add the edges to the graph
    (for-each (lambda (e)
		(let* ((ni (car e))
		       (nj (cdr e))
		       (i (car (alist-ref ni node-map)))
		       (j (car (alist-ref nj node-map))))
		  (add-edge! g (list i j (format "~A->~A" ni nj)))))
	      used-by)
    
    (test "graph cycles fold"
	  '(((8 0 "libfoobar_a->dax_h") (0 4 "dax_h->foo_cpp") 
	     (4 5 "foo_cpp->foo_o") (5 8 "foo_o->libfoobar_a")) 
	    ((8 0 "libfoobar_a->dax_h") (0 6 "dax_h->bar_cpp") 
	     (6 7 "bar_cpp->bar_o") (7 8 "bar_o->libfoobar_a")) 
	    ((8 0 "libfoobar_a->dax_h") (0 1 "dax_h->yow_h") 
	     (1 6 "yow_h->bar_cpp") (6 7 "bar_cpp->bar_o") 
	     (7 8 "bar_o->libfoobar_a")))
	  (fold g (lambda (cycle ax) (cons cycle ax)) (list)))
  ))

(test-exit)
