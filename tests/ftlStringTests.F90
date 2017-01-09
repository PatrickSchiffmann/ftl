! Copyright (c) 2016, 2017  Robert Rüger
!
! This file is part of of the Fortran Template Library.
!
! The Fortran Template Library is free software: you can redistribute it and/or
! modify it under the terms of the GNU Lesser General Public License as
! published by the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
!
! The Fortran Template Library is distributed in the hope that it will be
! useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
! General Public License for more details.
!
! You should have received a copy of the GNU Lesser General Public License along
! with the Fortran Template Library.  If not, see <http://www.gnu.org/licenses/>.


#include "ftlTestTools.inc"

module ftlStringTestsModule

   use ftlTestToolsModule
   use ftlStringModule

   implicit none
   private
   public :: ftlStringTests

contains


   subroutine ftlStringTests

      write (*,'(A)') 'Running ftlString tests ...'

      call testNewDefault
      call testAssignFStr
      call testAssignOther

      call testIteratorWriting

      call testHash

      call testFortranStandardMethods

      ! Python string methods:
      call testSplit
      call testStartsWith

      ! Other string methods:
      call testCountWords

   end subroutine


   subroutine testNewDefault
      type(ftlString) :: s

      call s%New()

   end subroutine


   subroutine testAssignFStr
      type(ftlString) :: s

      s = 'test'

      ASSERT(s%fstr == 'test')

   end subroutine


   subroutine testAssignOther
      type(ftlString) :: s1, s2

      s1 = 'testme'
      s2 = s1

      ASSERT(s1%fstr == 'testme')
      ASSERT(s2%fstr == 'testme')
      ASSERT(s1 == s2)

      s2 = 'theitcrowd'

      ASSERT(s1%fstr == 'testme')
      ASSERT(s2%fstr == 'theitcrowd')
      ASSERT(s1 /= s2)

   end subroutine


   subroutine testIteratorWriting
      type(ftlString) :: s
      type(ftlStringIterator) :: it

      s = 'TEfT'
      it = Begin(s)

      ASSERT(it%value == 'T')

      call it%Inc()

      ASSERT(it%value == 'E')

      call it%Inc()

      ASSERT(it%value == 'f')

      it%value = 'S'

      ASSERT(it%value == 'S')
      ASSERT(s == 'TEST')

   end subroutine


   subroutine testHash

      use ftlHashModule

      ASSERT(ftlHash(ftlString('testhash')) == ftlHash('testhash'))
      ASSERT(ftlHash(ftlString('another test')) == ftlHash('another test'))
      ASSERT(ftlHash(ftlString('and another')) == ftlHash('and another'))
      ASSERT(ftlHash(ftlString('number 4')) == ftlHash('number 4'))
      ASSERT(ftlHash(ftlString('the last')) == ftlHash('the last'))

   end subroutine


   subroutine testFortranStandardMethods
      type(ftlString) :: s1, s2

      s1 = '  this is a test with 4 trailing spaces and 2 leading spaces    '

      ASSERT(len(s1) == 64)
      ASSERT(len_trim(s1) == 60)

      s1 = trim(s1)

      ASSERT(len(s1) == 60)
      ASSERT(len_trim(s1) == 60)

      s1 = '   TEST '

      ASSERT(adjustl(s1) == 'TEST    ')
      ASSERT(len(adjustl(s1)) == 8)
      ASSERT(adjustr(s1) == '    TEST')
      ASSERT(len(adjustl(s1)) == 8)

      s1 = 'ABC'

      ASSERT(repeat(s1,3) == 'ABCABCABC')
      ASSERT(len(repeat(s1,3)) == 9)

      s2 = 'ABC1234ABC567ABC890'

      ASSERT(index(s2,s1,.true.) == 14)
      ASSERT(index(s2,s1) == 1)
      ASSERT(scan(s2,s1,.true.) == 16)
      ASSERT(scan(s2,s1) == 1)
      ASSERT(verify(s2,s1,.true.) == 19)
      ASSERT(verify(s2,s1) == 4)

   end subroutine


   subroutine testSplit
      type(ftlString) :: s
      type(ftlString), allocatable :: words(:)

      s = 'This is a simple sentence.'
      words = s%Split()

      ASSERT(size(words) == 5)
      ASSERT(words(1) == 'This')
      ASSERT(words(2) == 'is')
      ASSERT(words(3) == 'a')
      ASSERT(words(4) == 'simple')
      ASSERT(words(5) == 'sentence.')

      s = achar(9)//'This is a   simple sentence with weird whitespacing    issues.  '//achar(9)//' '
      words = s%Split()

      ASSERT(size(words) == 9)
      ASSERT(words(1) == 'This')
      ASSERT(words(2) == 'is')
      ASSERT(words(3) == 'a')
      ASSERT(words(4) == 'simple')
      ASSERT(words(5) == 'sentence')
      ASSERT(words(6) == 'with')
      ASSERT(words(7) == 'weird')
      ASSERT(words(8) == 'whitespacing')
      ASSERT(words(9) == 'issues.')

   end subroutine


   subroutine testStartsWith
      type(ftlString) :: s

      s = 'Teststartswith'
      ASSERT(s%StartsWith('Test'))

      s = 'Teststartswith'
      ASSERT(.not.s%StartsWith('Teststartswith but is toolong'))

      s = '  Teststartswith'
      ASSERT(.not.s%StartsWith('Test'))

      s = 'another test of startsWith'
      ASSERT(s%StartsWith([ftlString('Test'),ftlString('anot')]))
      ASSERT(.not.s%StartsWith([ftlString('Test'),ftlString('not there')]))

   end subroutine


   subroutine testCountWords
      type(ftlString) :: s

      s = 'this is a test'
      ASSERT(s%CountWords() == 4)

      s = 'this is a test with trailing spaces   '
      ASSERT(s%CountWords() == 7)

      s = '   this is a test with leading spaces   '
      ASSERT(s%CountWords() == 7)

      s = '   this is a test with leading and trailing spaces   '
      ASSERT(s%CountWords() == 9)

      s = achar(9)//'test containing '//achar(9)//'tabs'//achar(9)
      ASSERT(s%CountWords() == 3)

   end subroutine


end module