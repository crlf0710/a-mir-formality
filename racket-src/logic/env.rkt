#lang racket
(require redex/reduction-semantics
         "grammar.rkt")
(provide (all-defined-out))

(define-metafunction formality-logic
  ;; Returns the hypotheses in the environment
  env-with-hook : Hook -> Env

  [(env-with-hook Hook)
   (Hook RootUniverse () () () ())]
  )

(define-metafunction formality-logic
  ;; Given a query, creates and returns an environment for the query
  ;; along with the goal that is supposed to be solved in that environment.
  instantiate-query : Hook QueryGoal -> (Env Goal)

  [(instantiate-query Hook QueryGoal)
   (Env_query Goal)

   ; extract out
   (where/error (?- VarBinders_q (implies Hypotheses_q Goal)) QueryGoal)

   ; find the maximum universe of any variable in the query
   (where/error [(_ _ _ Universe_var) ...] VarBinders_q)
   (where/error Universe_max (max-universe RootUniverse Universe_var ...))

   ; initially our inference context is empty
   (where/error VarInequalities [])
   (where/error Substitution [])

   ;
   (where/error Env_query (Hook Universe_max VarBinders_q Substitution VarInequalities Hypotheses_q))
   ]
  )

(define-metafunction formality-logic
  ;; Returns the hook in the environment
  env-hook : Env -> Hook

  [(env-hook (Hook Universe VarBinders Substitution VarInequalities Hypotheses)) Hook]
  )

(define-metafunction formality-logic
  ;; Returns the hypotheses in the environment
  env-hypotheses : Env -> Hypotheses

  [(env-hypotheses (Hook Universe VarBinders Substitution VarInequalities Hypotheses)) Hypotheses]
  )

(define-metafunction formality-logic
  ;; Returns the `VarId -> Universe` mapping from the environment
  env-var-binders : Env -> VarBinders

  [(env-var-binders (Hook Universe VarBinders Substitution VarInequalities Hypotheses)) VarBinders]
  )

(define-metafunction formality-logic
  ;; Returns the substitution from the environment -- i.e., the currently inferred values
  ;; for any existential variables
  env-substitution : Env -> Substitution

  [(env-substitution (Hook Universe VarBinders Substitution VarInequalities Hypotheses)) Substitution]
  )

(define-metafunction formality-logic
  ;; Returns the substitution from the environment -- i.e., the currently inferred values
  ;; for any existential variables
  env-inequalities : Env -> VarInequalities

  [(env-inequalities (Hook Universe VarBinders Substitution VarInequalities Hypotheses)) VarInequalities]
  )

(define-metafunction formality-logic
  ;; Returns the current maximum universe in the environment
  env-universe : Env -> Universe

  [(env-universe (Hook Universe VarBinders Substitution VarInequalities Hypotheses)) Universe]
  )

(define-metafunction formality-logic
  ;; Replace the inequalities in the universe with the given set.
  env-with-inequalities : Env VarInequalities -> Env

  [(env-with-inequalities (Hook Universe VarBinders Substitution _ Hypotheses) VarInequalities)
   (Hook Universe VarBinders Substitution VarInequalities Hypotheses)
   ]
  )

(define-metafunction formality-logic
  ;; Returns the existential `VarId` from the environment
  existential-vars-in-env : Env -> VarIds

  [(existential-vars-in-env Env)
   (existential-vars-from-binders VarBinders)
   (where/error VarBinders (env-var-binders Env))
   ]
  )

(define-metafunction formality-logic
  ;; Filters out universal (∀) binders and returns just the VarIds of the existential ones.
  existential-vars-from-binders : VarBinders -> VarIds

  [(existential-vars-from-binders ()) ()]

  [(existential-vars-from-binders ((_ _ ∀ _) VarBinder_2 ...))
   (existential-vars-from-binders (VarBinder_2 ...))]

  [(existential-vars-from-binders ((VarId_1 _ ∃ _) VarBinder_2 ...))
   (VarId_1 VarId_2 ...)
   (where/error (VarId_2 ...) (existential-vars-from-binders (VarBinder_2 ...)))]

  )

(define-metafunction formality-logic
  ;; Extend `Env`, mapping the names in `VarIds` to the current universe
  env-with-vars-in-current-universe : Env Quantifier KindedVarIds -> Env

  [(env-with-vars-in-current-universe Env Quantifier ((ParameterKind VarId) ...))
   (Hook Universe ((VarId ParameterKind Quantifier Universe) ... VarBinder ...) Substitution VarInequalities Hypotheses)
   (where/error (Hook Universe (VarBinder ...) Substitution VarInequalities Hypotheses) Env)
   ]
  )

(define-metafunction formality-logic
  ;; Extend `Env` with a single variable declared in the given universe with the given quantifier.
  env-with-var : Env VarId ParameterKind Quantifier Universe -> Env

  [(env-with-var Env VarId ParameterKind Quantifier Universe)
   (Hook_Env Universe_Env ((VarId ParameterKind Quantifier Universe) VarBinder_Env ...) Substitution_Env VarInequalities_Env Hypotheses_Env)
   (where/error (Hook_Env Universe_Env (VarBinder_Env ...) Substitution_Env VarInequalities_Env Hypotheses_Env) Env)
   ]
  )

(define-metafunction formality-logic
  ;; Returns a list of fresh var-ids that are not found in `Term`.
  ;;
  ;; The names are based on `VarIds` (i.e., one name will be returned per item in `VarIds`).
  fresh-var-ids : Term VarIds -> VarIds

  [(fresh-var-ids Term VarIds)
   ,(variables-not-in (term Term) (term VarIds))
   ]
  )

(define-metafunction formality-logic
  ;; Returns the hypotheses in the environment
  env-with-hypotheses : Env Hypotheses -> Env

  [(env-with-hypotheses Env ()) Env]

  [(env-with-hypotheses Env (Hypothesis_0 Hypothesis_1 ...))
   (env-with-hypotheses Env_1 (Hypothesis_1 ...))
   (where/error Env_1 (env-with-hypothesis Env Hypothesis_0))
   ]
  )

(define-metafunction formality-logic
  ;; Adds a hypothesis (if not already present)
  env-with-hypothesis : Env Hypothesis -> Env

  [(env-with-hypothesis Env Hypothesis_1)
   Env
   (where #t (in? Hypothesis_1 (env-hypotheses Env)))
   ]

  [(env-with-hypothesis (Hook Universe VarBinders Substitution VarInequalities (Hypothesis_0 ...)) Hypothesis_1)
   (Hook Universe VarBinders Substitution VarInequalities (Hypothesis_0 ... Hypothesis_1))
   ]

  )

(define-metafunction formality-logic
  ;; Returns an `Env` where `VarId` is guaranteed to contain only elements from
  ;; `Universe`.
  env-with-var-limited-to-universe : Env VarId Universe -> Env

  [(env-with-var-limited-to-universe Env VarId Universe_max)
   (Hook Universe (VarBinder_0 ... (VarId ParameterKind Quantifier Universe_new) VarBinder_1 ...) Substitution VarInequalities Hypotheses)
   (where/error (Hook Universe (VarBinder_0 ... (VarId ParameterKind Quantifier Universe_old) VarBinder_1 ...) Substitution VarInequalities Hypotheses) Env)
   (where/error Universe_new (min-universe Universe_old Universe_max))
   ]
  )

(define-metafunction formality-logic
  ;; Returns an `Env` where each of the given `VarId`s is guaranteed to
  ;; contain only elements from `Universe`.
  env-with-vars-limited-to-universe : Env (VarId ...) Universe -> Env

  [(env-with-vars-limited-to-universe Env () Universe_max)
   Env]

  [(env-with-vars-limited-to-universe Env (VarId_0 VarId_1 ...) Universe_max)
   (env-with-vars-limited-to-universe Env (VarId_1 ...) Universe_max)
   (where (universe 0) (universe-of-var-in-env Env VarId_0))]

  [(env-with-vars-limited-to-universe Env (VarId_0 VarId_1 ...) Universe_max)
   (env-with-vars-limited-to-universe Env_1 (VarId_1 ...) Universe_max)
   (where/error Env_1 (env-with-var-limited-to-universe Env VarId_0 Universe_max))
   ]
  )

(define-metafunction formality-logic
  ;; Returns an environment where the current universe is incremented, and returns
  ;; this new universe.
  env-with-incremented-universe : Env -> Env

  [(env-with-incremented-universe Env)
   (Hook Universe_new VarBinders Substitution VarInequalities Hypotheses)

   (where/error (Hook Universe VarBinders Substitution VarInequalities Hypotheses) Env)
   (where/error Universe_new (next-universe Universe))
   ]

  )

(define-metafunction formality-logic
  ;; If this variable is declared in the environment, return its
  ;; quantifier/universe (or `()` otherwise).
  var-binding-in-env : Env VarId -> VarBinder or ()

  [(var-binding-in-env Env VarId)
   (VarId ParameterKind Quantifier Universe)
   (where (_ ... (VarId ParameterKind Quantifier Universe) _ ...) (env-var-binders Env))]

  [(var-binding-in-env Env VarId)
   ()]

  )

(define-metafunction formality-logic
  ;; Finds the declared universe of `VarId` in the given environment.
  ;;
  ;; If `VarId` is not found in the `Env`, returns the root universe. This is a useful
  ;; default for random user-given names like `i32` or `Vec`.
  universe-of-var-in-env : Env VarId -> Universe

  [(universe-of-var-in-env Env VarId)
   Universe
   (where (_ _ Quantifier Universe) (var-binding-in-env Env VarId))]

  [(universe-of-var-in-env Env VarId)
   RootUniverse
   (where () (var-binding-in-env Env VarId))]

  )


(define-metafunction formality-logic
  ;; True if this variable is an existential variable defined in the environment.
  env-contains-var : Env VarId -> boolean

  [(env-contains-var Env VarId)
   #f
   (where () (var-binding-in-env Env VarId))]

  [(env-contains-var Env VarId)
   #t]

  )

(define-metafunction formality-logic
  ;; True if this variable is an existential variable defined in the environment.
  env-contains-existential-var : Env VarId -> boolean

  [(env-contains-existential-var Env VarId)
   #t
   (where (_ _ ∃ _) (var-binding-in-env Env VarId))]

  [(env-contains-existential-var Env VarId)
   #f]

  )

(define-metafunction formality-logic
  ;; True if this variable is an existential variable defined in the environment
  ;; that has not yet been mapped to a specific value.
  env-contains-unmapped-existential-var : Env VarId -> boolean

  [(env-contains-unmapped-existential-var Env VarId)
   (all? (env-contains-existential-var Env VarId)
         (not? (env-maps-var Env VarId)))
   ]
  )

(define-metafunction formality-logic
  ;; True if the Env's substitution includes a mapping for VarId.
  env-maps-var : Env VarId -> boolean

  [(env-maps-var Env VarId)
   #t
   (where (_ ... (VarId _) _ ...) (env-substitution Env))
   ]

  [(env-maps-var Env VarId)
   #f]

  )

(define-metafunction formality-logic
  ;; True if this variable is an placeholder (universal) variable defined in the environment.
  env-contains-placeholder-var : Env VarId -> boolean

  [(env-contains-placeholder-var Env VarId)
   #t
   (where (_ _ ∀ _) (var-binding-in-env Env VarId))]

  [(env-contains-placeholder-var Env VarId)
   #f]

  )

(define-metafunction formality-logic
  ;; Increments a universe to return the next largest universe.
  next-universe : Universe -> Universe

  [(next-universe (universe natural))
   (universe ,(+ 1 (term natural)))]
  )

(define-metafunction formality-logic
  ;; True if the given variable appears free in the given term.
  appears-free : VarId Term -> boolean

  [(appears-free VarId Term)
   ,(not (alpha-equivalent? formality-logic (term Term) (term Term_1)))
   (where/error Term_1 (substitute Term VarId (rigid-ty VarId ())))
   ]
  )

(define-metafunction formality-logic
  ;; True if any of the given variable appears free in the given term.
  any-appears-free : VarIds Term -> boolean

  [(any-appears-free (_ ... VarId _ ...) Term)
   #t
   (where #t (appears-free VarId Term))]

  [(any-appears-free _ _)
   #f]

  )

(define-metafunction formality-logic
  ;; Returns the set of variables that appear free in the given term;
  ;; only returns variables that are defined in the environment. This includes
  ;; both existential (inference) and universal (placeholder) variables.
  ;; Everything else is assumed to be a universal constant or keyword.
  free-variables : Env Term -> (VarId ...)

  [(free-variables Env (Quantifier ((ParameterKind VarId_bound) ...) Term))
   ,(set-subtract (term VarIds_free) (term (VarId_bound ...)))
   (where/error VarIds_free (free-variables Env Term))]

  [(free-variables Env VarId)
   (VarId)
   (where #t (env-contains-var Env VarId))]

  [(free-variables Env (Term ...))
   ,(apply set-union (term (() VarIds ...)))
   (where/error (VarIds ...) ((free-variables Env Term) ...))
   ]

  [(free-variables Env _)
   ()]

  )

(define-metafunction formality-logic
  ;; Returns the set of variables that appear free in the given term;
  ;; only returns variables that are defined in the environment. This includes
  ;; both existential (inference) and universal (placeholder) variables.
  ;; Everything else is assumed to be a universal constant or keyword.
  free-existential-variables : Env Term -> (VarId ...)

  [(free-existential-variables Env (Quantifier ((ParameterKind VarId_bound) ...) Term))
   ,(set-subtract (term VarIds_free) (term (VarId_bound ...)))
   (where/error VarIds_free (free-existential-variables Env Term))]

  [(free-existential-variables Env VarId)
   (VarId)
   (where #t (env-contains-existential-var Env VarId))]

  [(free-existential-variables Env (Term ...))
   ,(apply set-union (term (() VarIds ...)))
   (where/error (VarIds ...) ((free-existential-variables Env Term) ...))
   ]

  [(free-existential-variables Env _)
   ()]

  )

(define-metafunction formality-logic
  ;; Returns the set of universally quantified variables from
  ;; within the term -- this excludes global constants like
  ;; adt names. So e.g. if you have `(rigid-ty Vec (X))`,
  ;; this would return `(X)` (presuming `X` was forall'd).
  placeholder-variables : Env Term -> (VarId ...)

  [(placeholder-variables Env VarId)
   (VarId)
   (where #t (env-contains-placeholder-var Env VarId))
   ]

  [(placeholder-variables Env (Term ...))
   ,(apply set-union (term (() VarIds ...)))
   (where/error (VarIds ...) ((placeholder-variables Env Term) ...))
   ]

  [(placeholder-variables Env _)
   ()]

  )

(define-metafunction formality-logic
  ;; Boolean operator
  not? : boolean -> boolean
  [(not? #f) #t]
  [(not? #t) #f]
  )

(define-metafunction formality-logic
  ;; Boolean operator
  all? : boolean ... -> boolean
  [(all? #t ...) #t]
  [(all? _ ...) #f]
  )

(define-metafunction formality-logic
  ;; Boolean operator
  any? : boolean ... -> boolean
  [(any? _ ... #t _ ...) #t]
  [(any? _ ...) #f]
  )

(define-metafunction formality-logic
  ;; `in? Term Terms` is true if `Term` is in `Terms`;
  ;; it takes binding forms into account, so `forall (K1 X1) X1` and `forall (K1 X2) X2`
  ;; are considered equal.
  in? : Term (Term ...) -> boolean
  [(in? Term_0 (_ ... Term_1 _ ...))
   #t
   (where #t ,(alpha-equivalent? (term Term_0) (term Term_1)))
   ]

  [(in? _ _)
   #f
   ]
  )

(define-metafunction formality-logic
  ;; Repeat a given term multiple times
  repeat-n-times : Term number -> (Term ...)
  [(repeat-n-times Term 0) ()]
  [(repeat-n-times Term number)
   (Term Term_1 ...)
   (where/error (Term_1 ...) (repeat-n-times Term ,(- (term number) 1)))]
  )

(define-metafunction formality-logic
  ;; True if two lists have the same length.
  same-length : Terms Terms -> boolean
  [(same-length (Term_0 ..._1) (Term_1 ..._1)) #t]
  [(same-length _ _) #f]
  )

(define-metafunction formality-logic
  ;; `in?` specialized to Id for a micro-optimization
  in?/id : AnyId (AnyId ...) -> boolean
  [(in?/id AnyId (_ ... AnyId _ ...)) #t]
  [(in?/id _ _) #f]
  )

(define-metafunction formality-logic
  ;; `in?` specialized to Id for a micro-optimization
  all-in?/id : (AnyId ...) (AnyId ...) -> boolean
  [(all-in?/id (AnyId_0 ...) AnyIds)
   (all? ((in?/id AnyId_0 AnyIds) ...))
   ]
  )

(define-metafunction formality-logic
  ;; Returns the smallest of the various universes provided
  min-universe : Universe ... -> Universe
  [(min-universe (universe number) ...)
   (universe ,(apply min (term (number ...))))
   ])

(define-metafunction formality-logic
  ;; Returns the smallest of the various universes provided
  max-universe : Universe ... -> Universe
  [(max-universe (universe number) ...)
   (universe ,(apply max (term (number ...))))
   ])

(define-metafunction formality-logic
  ;; True if `Universe_0` includes all values of `Universe_1`
  universe-includes : Universe_0 Universe_1 -> boolean
  [(universe-includes (universe number_0) (universe number_1))
   ,(>= (term number_0) (term number_1))])

(define-metafunction formality-logic
  ;; Flatten a list of lists.
  flatten : ((Term ...) ...) -> (Term ...)

  [(flatten ((Term ...) ...)) (Term ... ...)]
  )
